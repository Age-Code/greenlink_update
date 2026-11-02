package com.greenlink.greenlink.domain.iot;

import com.greenlink.greenlink.domain.plant.UserPlant;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(
        name = "pump_channel",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uq_pump_channel_user_plant",
                        columnNames = "user_plant_id"
                )
        }
)
// PumpChannel — 도메인 모델
public class PumpChannel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 펌프가 속한 재배 공간
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grow_space_id", nullable = false)
    private GrowSpace growSpace;

    // 이 펌프가 물을 주는 대상 식물
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_plant_id", nullable = false)
    private UserPlant userPlant;

    // 펌프를 실제로 제어하는 라즈베리파이
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "raspberry_device_id", nullable = false)
    private IotDevice raspberryDevice;

    @Column(nullable = false, length = 100)
    private String channelName;

    // 라즈베리파이 GPIO 번호
    private Integer gpioPin;

    // 릴레이 모듈 기준 채널 번호
    private Integer relayChannel;

    @Column(nullable = false)
    private Boolean active;

    @Column(nullable = false)
    private boolean deleted;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime modifiedAt;

    // PumpChannel 생성
    @Builder
    private PumpChannel(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice raspberryDevice,
            String channelName,
            Integer gpioPin,
            Integer relayChannel
    ) {
        if (!raspberryDevice.isRaspberryPi()) {
            throw new IllegalStateException("펌프 채널은 라즈베리파이 기기에만 연결할 수 있습니다.");
        }

        this.growSpace = growSpace;
        this.userPlant = userPlant;
        this.raspberryDevice = raspberryDevice;
        this.channelName = channelName;
        this.gpioPin = gpioPin;
        this.relayChannel = relayChannel;
        this.active = true;
        this.deleted = false;
    }

    // create 생성
    public static PumpChannel create(
            GrowSpace growSpace,
            UserPlant userPlant,
            IotDevice raspberryDevice,
            String channelName,
            Integer gpioPin,
            Integer relayChannel
    ) {
        return PumpChannel.builder()
                .growSpace(growSpace)
                .userPlant(userPlant)
                .raspberryDevice(raspberryDevice)
                .channelName(channelName)
                .gpioPin(gpioPin)
                .relayChannel(relayChannel)
                .build();
    }

    // update Channel Info 수정
    public void updateChannelInfo(
            String channelName,
            Integer gpioPin,
            Integer relayChannel
    ) {
        this.channelName = channelName;
        this.gpioPin = gpioPin;
        this.relayChannel = relayChannel;
    }

    // 비활성화 처리
    public void deactivate() {
        this.active = false;
    }

    // 활성화 처리
    public void activate() {
        this.active = true;
    }

    // delete 삭제
    public void delete() {
        this.deleted = true;
        this.active = false;
    }

    // 생성 시각 초기화
    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.modifiedAt = now;

        if (this.active == null) {
            this.active = true;
        }
    }

    // 수정 시각 갱신
    @PreUpdate
    public void preUpdate() {
        this.modifiedAt = LocalDateTime.now();
    }
}
