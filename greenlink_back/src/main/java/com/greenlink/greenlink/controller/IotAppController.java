package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.iot.IotAppDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.IotAppService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// IoT 앱 Controller — 최신 조회, 수동 물주기/조명/센서 새로고침
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/user-plants/{userPlantId}/iot")
public class IotAppController {

    private final IotAppService iotAppService;

    // 내 식물 IoT 최신 상태 조회
    @GetMapping("/latest")
    public ApiResponse<IotAppDto.IotLatestResDto> getLatestIotStatus(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        IotAppDto.IotLatestResDto response =
                iotAppService.getLatestIotStatus(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("최신 IoT 상태 조회 성공", response);
    }

    // 내 식물 사진 기록 조회
    @GetMapping("/images")
    public ApiResponse<List<IotAppDto.PlantImageDto>> getPlantImages(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        List<IotAppDto.PlantImageDto> response =
                iotAppService.getPlantImages(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("식물 이미지 목록 조회 성공", response);
    }

    // 물 주기 요청
    @PostMapping("/water")
    public ApiResponse<IotAppDto.WaterCommandResDto> requestWater(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        IotAppDto.WaterCommandResDto response =
                iotAppService.requestWater(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("급수 명령이 요청되었습니다.", response);
    }

    // 조명 켜기 요청
    @PostMapping("/light/on")
    public ApiResponse<IotAppDto.LightCommandResDto> requestLightOn(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        IotAppDto.LightCommandResDto response =
                iotAppService.requestLightOn(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("조명 켜기 명령이 요청되었습니다.", response);
    }

    // 조명 끄기 요청
    @PostMapping("/light/off")
    public ApiResponse<IotAppDto.LightCommandResDto> requestLightOff(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        IotAppDto.LightCommandResDto response =
                iotAppService.requestLightOff(
                        userDetails.getUserId(),
                        userPlantId
                );

        return ApiResponse.success("조명 끄기 명령이 요청되었습니다.", response);
    }

    // 센서 새로고침 요청
    @PostMapping("/refresh")
    public ApiResponse<IotAppDto.DeviceCommandResDto> requestSensorRefresh(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long userPlantId
    ) {
        IotAppDto.DeviceCommandResDto response =
                iotAppService.requestSensorRefresh(
                        userPlantId,
                        userDetails.getUserId()
                );

        return ApiResponse.success("센서 새로고침 명령이 요청되었습니다.", response);
    }
}
