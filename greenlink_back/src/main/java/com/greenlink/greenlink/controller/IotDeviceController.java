package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.common.ApiResponse;
import com.greenlink.greenlink.dto.iot.IotDeviceDto;
import com.greenlink.greenlink.service.IotCommandService;
import com.greenlink.greenlink.service.IotDeviceDataService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;

// IotDeviceController — API 요청 처리
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/iot")
public class IotDeviceController {

    private final IotDeviceDataService iotDeviceDataService;
    private final IotCommandService iotCommandService;

    // 라즈베리파이 환경 데이터 전송
    @PostMapping("/raspberry/environment")
    public ApiResponse<IotDeviceDto.RaspberryEnvironmentResDto> saveRaspberryEnvironment(
            @RequestHeader("X-DEVICE-KEY") String deviceKey,
            @Valid @RequestBody IotDeviceDto.RaspberryEnvironmentReqDto request
    ) {
        IotDeviceDto.RaspberryEnvironmentResDto response =
                iotDeviceDataService.saveRaspberryEnvironment(deviceKey, request);

        return ApiResponse.success("라즈베리파이 환경 데이터가 저장되었습니다.", response);
    }

    // ESP 토양수분 데이터 전송
    @PostMapping("/esp/soil-moisture")
    public ApiResponse<IotDeviceDto.EspSoilMoistureResDto> saveEspSoilMoisture(
            @RequestHeader("X-DEVICE-KEY") String deviceKey,
            @Valid @RequestBody IotDeviceDto.EspSoilMoistureReqDto request
    ) {
        IotDeviceDto.EspSoilMoistureResDto response =
                iotDeviceDataService.saveEspSoilMoisture(deviceKey, request);

        return ApiResponse.success("ESP 토양수분 데이터가 저장되었습니다.", response);
    }

    // 라즈베리파이 식물 이미지 업로드
    @PostMapping(
            value = "/plant-images",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ApiResponse<IotDeviceDto.PlantImageUploadResDto> uploadPlantImage(
            @RequestHeader("X-DEVICE-KEY") String deviceKey,
            @RequestPart("file") MultipartFile file,
            @RequestParam(required = false) Long userPlantId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
            LocalDateTime capturedAt
    ) {
        IotDeviceDto.PlantImageUploadResDto response =
                iotDeviceDataService.savePlantImage(
                        deviceKey,
                        file,
                        userPlantId,
                        capturedAt
                );

        return ApiResponse.success("식물 이미지가 저장되었습니다.", response);
    }

    // 라즈베리파이 대기 명령 조회
    @GetMapping("/commands/pending")
    public ApiResponse<List<IotDeviceDto.PendingCommandResDto>> getPendingCommands(
            @RequestHeader("X-DEVICE-KEY") String deviceKey
    ) {
        List<IotDeviceDto.PendingCommandResDto> response =
                iotCommandService.getPendingCommands(deviceKey);

        return ApiResponse.success("대기 중인 명령 조회 성공", response);
    }

    // 명령 처리 시작 보고
    @PatchMapping("/commands/{commandId}/processing")
    public ApiResponse<IotDeviceDto.CommandProcessingResDto> markCommandProcessing(
            @RequestHeader("X-DEVICE-KEY") String deviceKey,
            @PathVariable Long commandId
    ) {
        IotDeviceDto.CommandProcessingResDto response =
                iotCommandService.markCommandProcessing(deviceKey, commandId);

        return ApiResponse.success("명령 처리 상태가 변경되었습니다.", response);
    }

    // 명령 처리 완료 보고
    @PatchMapping("/commands/{commandId}/complete")
    public ApiResponse<IotDeviceDto.CommandCompleteResDto> completeCommand(
            @RequestHeader("X-DEVICE-KEY") String deviceKey,
            @PathVariable Long commandId,
            @Valid @RequestBody IotDeviceDto.CommandCompleteReqDto request
    ) {
        IotDeviceDto.CommandCompleteResDto response =
                iotCommandService.completeCommand(
                        deviceKey,
                        commandId,
                        request
                );

        return ApiResponse.success("명령 처리 결과가 저장되었습니다.", response);
    }
}
