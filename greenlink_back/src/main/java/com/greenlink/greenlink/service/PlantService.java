package com.greenlink.greenlink.service;

import com.greenlink.greenlink.domain.plant.Plant;
import com.greenlink.greenlink.dto.PlantDto;
import com.greenlink.greenlink.repository.PlantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

// PlantService — 비즈니스 로직 처리
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PlantService {

    private final PlantRepository plantRepository;

    public List<PlantDto.ListResDto> getPlants() {
        return plantRepository.findAllByDeletedFalse()
                .stream()
                .map(PlantDto.ListResDto::from)
                .toList();
    }

    public PlantDto.DetailResDto getPlant(Long plantId) {
        Plant plant = plantRepository.findByIdAndDeletedFalse(plantId)
                .orElseThrow(() -> new IllegalArgumentException("식물을 찾을 수 없습니다."));

        return PlantDto.DetailResDto.from(plant);
    }
}