package com.greenlink.greenlink.domain.item;

import com.greenlink.greenlink.common.BaseEntity;
import com.greenlink.greenlink.domain.plant.Plant;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

// Item — 도메인 모델
@Getter
@Entity
@Table(name = "item")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Item extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 아이템 이름: 바질 씨앗, 기본 화분, 영양제 등
    @Column(nullable = false, length = 50)
    private String name;

    // 아이템 타입: SEED, POT, NUTRIENT
    @Enumerated(EnumType.STRING)
    @Column(name = "item_type", nullable = false, length = 30)
    private ItemType itemType;

    // 아이템 설명
    @Column(columnDefinition = "TEXT")
    private String description;

    // 아이템 이미지
    @Column(name = "image_url", length = 500)
    private String imageUrl;

    // 씨앗일 경우 연결되는 식물
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "linked_plant_id")
    private Plant linkedPlant;

    // Item 생성
    private Item(String name, ItemType itemType, String description, String imageUrl, Plant linkedPlant) {
        this.name = name;
        this.itemType = itemType;
        this.description = description;
        this.imageUrl = imageUrl;
        this.linkedPlant = linkedPlant;
    }

    // create Seed 생성
    public static Item createSeed(String name, String description, String imageUrl, Plant linkedPlant) {
        if (linkedPlant == null) {
            throw new IllegalArgumentException("씨앗 아이템은 연결된 식물이 필요합니다.");
        }

        return new Item(name, ItemType.SEED, description, imageUrl, linkedPlant);
    }

    // create Pot 생성
    public static Item createPot(String name, String description, String imageUrl) {
        return new Item(name, ItemType.POT, description, imageUrl, null);
    }

    // create Nutrient 생성
    public static Item createNutrient(String name, String description, String imageUrl) {
        return new Item(name, ItemType.NUTRIENT, description, imageUrl, null);
    }

    // update 수정
    public void update(String name, String description, String imageUrl) {
        this.name = name;
        this.description = description;
        this.imageUrl = imageUrl;
    }
}