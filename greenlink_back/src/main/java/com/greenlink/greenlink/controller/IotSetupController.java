package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.iot.IotSetupDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.IotSetupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// IotSetupController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/iot")
public class IotSetupController {

    private final IotSetupService iotSetupService;

    // 재배 공간 생성
    @PostMapping("/grow-spaces")
    public ApiResponse<IotSetupDto.GrowSpaceResDto> createGrowSpace(
            @Valid @RequestBody IotSetupDto.GrowSpaceCreateReqDto request
    ) {
        IotSetupDto.GrowSpaceResDto response =
                iotSetupService.createGrowSpace(request);

        return ApiResponse.success("재배 공간이 생성되었습니다.", response);
    }

    // 재배 공간 목록 조회
    @GetMapping("/grow-spaces")
    public ApiResponse<List<IotSetupDto.GrowSpaceResDto>> getGrowSpaces() {
        List<IotSetupDto.GrowSpaceResDto> response =
                iotSetupService.getGrowSpaces();

        return ApiResponse.success("재배 공간 목록 조회 성공", response);
    }

    // 재배 공간에 식물 연결
    @PostMapping("/grow-spaces/{growSpaceId}/plants")
    public ApiResponse<IotSetupDto.GrowSpacePlantResDto> connectPlantToGrowSpace(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long growSpaceId,
            @Valid @RequestBody IotSetupDto.ConnectPlantReqDto request
    ) {
        IotSetupDto.GrowSpacePlantResDto response =
                iotSetupService.connectPlantToGrowSpace(
                        userDetails.getUserId(),
                        growSpaceId,
                        request
                );

        return ApiResponse.success("재배 공간에 식물이 연결되었습니다.", response);
    }

    // 재배 공간에 연결된 식물 목록 조회
    @GetMapping("/grow-spaces/{growSpaceId}/plants")
    public ApiResponse<List<IotSetupDto.GrowSpacePlantResDto>> getGrowSpacePlants(
            @PathVariable Long growSpaceId
    ) {
        List<IotSetupDto.GrowSpacePlantResDto> response =
                iotSetupService.getGrowSpacePlants(growSpaceId);

        return ApiResponse.success("재배 공간 식물 목록 조회 성공", response);
    }

    // IoT 기기 등록
    @PostMapping("/devices")
    public ApiResponse<IotSetupDto.DeviceResDto> createDevice(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody IotSetupDto.DeviceCreateReqDto request
    ) {
        IotSetupDto.DeviceResDto response =
                iotSetupService.createDevice(
                        userDetails.getUserId(),
                        request
                );

        return ApiResponse.success("IoT 기기가 등록되었습니다.", response);
    }

    // IoT 기기 목록 조회
    @GetMapping("/devices")
    public ApiResponse<List<IotSetupDto.DeviceResDto>> getDevices() {
        List<IotSetupDto.DeviceResDto> response =
                iotSetupService.getDevices();

        return ApiResponse.success("IoT 기기 목록 조회 성공", response);
    }

    // 펌프 채널 등록
    @PostMapping("/pump-channels")
    public ApiResponse<IotSetupDto.PumpChannelResDto> createPumpChannel(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody IotSetupDto.PumpChannelCreateReqDto request
    ) {
        IotSetupDto.PumpChannelResDto response =
                iotSetupService.createPumpChannel(
                        userDetails.getUserId(),
                        request
                );

        return ApiResponse.success("펌프 채널이 등록되었습니다.", response);
    }

    // 펌프 채널 목록 조회
    @GetMapping("/pump-channels")
    public ApiResponse<List<IotSetupDto.PumpChannelResDto>> getPumpChannels() {
        List<IotSetupDto.PumpChannelResDto> response =
                iotSetupService.getPumpChannels();

        return ApiResponse.success("펌프 채널 목록 조회 성공", response);
    }
}
