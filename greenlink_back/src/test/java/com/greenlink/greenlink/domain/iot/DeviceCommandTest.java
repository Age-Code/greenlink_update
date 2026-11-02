package com.greenlink.greenlink.domain.iot;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class DeviceCommandTest {

    @Test
    void waterCommandUsesDurationWithinFailClosedLimit() {
        assertThat(DeviceCommand.MAX_WATER_DURATION_SECONDS).isEqualTo(1);

        GrowSpace growSpace = growSpace();
        DeviceCommand command = DeviceCommand.createWaterCommand(
                growSpace,
                null,
                raspberryPi(growSpace),
                null
        );

        assertThat(command.getDurationSeconds())
                .isPositive()
                .isLessThanOrEqualTo(DeviceCommand.MAX_WATER_DURATION_SECONDS)
                .isEqualTo(1);
    }

    @Test
    void waterCommandRejectsDurationOutsideFailClosedLimit() {
        assertInvalidWaterDuration(null);
        assertInvalidWaterDuration(0);
        assertInvalidWaterDuration(-1);
        assertInvalidWaterDuration(DeviceCommand.MAX_WATER_DURATION_SECONDS + 1);
    }

    @Test
    void pendingCommandBecomesStaleAfterTimeout() {
        DeviceCommand command = waterCommand();
        LocalDateTime now = LocalDateTime.now();

        assertThat(command.isStale(now)).isFalse();

        ReflectionTestUtils.setField(
                command,
                "requestedAt",
                now.minusMinutes(DeviceCommand.STALE_COMMAND_TIMEOUT_MINUTES + 1)
        );

        assertThat(command.isStale(now)).isTrue();
    }

    @Test
    void processingCommandUsesProcessedAtAsStaleBaseline() {
        DeviceCommand command = waterCommand();
        LocalDateTime now = LocalDateTime.now();

        ReflectionTestUtils.setField(command, "requestedAt", now.minusHours(1));
        command.markProcessing();

        // 요청은 오래됐어도 방금 처리를 시작했으면 방치가 아니다.
        assertThat(command.isStale(now)).isFalse();

        ReflectionTestUtils.setField(
                command,
                "processedAt",
                now.minusMinutes(DeviceCommand.STALE_COMMAND_TIMEOUT_MINUTES + 1)
        );

        assertThat(command.isStale(now)).isTrue();
    }

    @Test
    void completedCommandIsNeverStale() {
        DeviceCommand command = waterCommand();
        command.markProcessing();
        command.completeSuccess("급수 완료");

        ReflectionTestUtils.setField(command, "requestedAt", LocalDateTime.now().minusDays(1));
        ReflectionTestUtils.setField(command, "processedAt", LocalDateTime.now().minusDays(1));

        assertThat(command.isStale(LocalDateTime.now())).isFalse();
    }

    private DeviceCommand waterCommand() {
        GrowSpace growSpace = growSpace();

        return DeviceCommand.createWaterCommand(
                growSpace,
                null,
                raspberryPi(growSpace),
                null
        );
    }

    private void assertInvalidWaterDuration(Integer durationSeconds) {
        GrowSpace growSpace = growSpace();

        assertThatIllegalArgumentException()
                .isThrownBy(() -> DeviceCommand.builder()
                        .growSpace(growSpace)
                        .userPlant(null)
                        .iotDevice(raspberryPi(growSpace))
                        .pumpChannel(null)
                        .commandType(CommandType.WATER)
                        .durationSeconds(durationSeconds)
                        .build());
    }

    private GrowSpace growSpace() {
        return GrowSpace.create("test-space", null);
    }

    private IotDevice raspberryPi(GrowSpace growSpace) {
        return IotDevice.createRaspberryPi(
                growSpace,
                "test-pi",
                "test-device-key"
        );
    }
}
