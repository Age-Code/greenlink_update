package com.greenlink.greenlink.controller;

import com.greenlink.greenlink.domain.iot.DeviceType;
import com.greenlink.greenlink.domain.item.ItemType;
import com.greenlink.greenlink.domain.quest.QuestType;
import com.greenlink.greenlink.domain.quest.ResetCycle;
import com.greenlink.greenlink.domain.quest.TargetType;
import com.greenlink.greenlink.domain.user.UserRole;
import com.greenlink.greenlink.dto.AdminDto;
import com.greenlink.greenlink.dto.AuthDto;
import com.greenlink.greenlink.security.CustomUserDetails;
import com.greenlink.greenlink.service.AdminDashboardService;
import com.greenlink.greenlink.service.AdminService;
import com.greenlink.greenlink.service.AuthService;
import com.greenlink.greenlink.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

// 관리자 Thymeleaf Controller — 웹 화면
@Slf4j
@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminWebController {

    // 관리자 JWT cookie — /admin 경로에서만 전송되고 JS에서 읽을 수 없다.
    public static final String ADMIN_TOKEN_COOKIE = "jwt_token";
    private static final String ADMIN_COOKIE_PATH = "/admin";
    private static final long ADMIN_COOKIE_MAX_AGE_SECONDS = 86400;

    private final AdminService adminService;
    private final AdminDashboardService adminDashboardService;
    private final AuthService authService;
    private final UserService userService;

    // 로그인 화면
    @GetMapping("/login")
    public String login() {
        return "admin/login";
    }

    // 로그인 처리 — ADMIN 계정만 HttpOnly cookie로 JWT 발급
    @PostMapping("/login")
    public String loginSubmit(
            @RequestParam String email,
            @RequestParam String password,
            HttpServletRequest request,
            HttpServletResponse response
    ) {
        AuthDto.LoginResDto loginResult;

        try {
            loginResult = authService.login(new AuthDto.LoginReqDto(email, password));
        } catch (RuntimeException e) {
            return "redirect:/admin/login?error";
        }

        if (!UserRole.ADMIN.name().equals(loginResult.getUser().getRole())) {
            return "redirect:/admin/login?error";
        }

        response.addHeader(
                HttpHeaders.SET_COOKIE,
                adminTokenCookie(loginResult.getAccessToken(), ADMIN_COOKIE_MAX_AGE_SECONDS, request.isSecure()).toString()
        );

        return "redirect:/admin";
    }

    // 로그아웃 — tokenVersion 증가로 기존 JWT 무효화 후 cookie 삭제
    @PostMapping("/logout")
    public String logout(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            HttpServletRequest request,
            HttpServletResponse response
    ) {
        if (userDetails != null) {
            userService.logout(userDetails.getUserId());
        }

        response.addHeader(HttpHeaders.SET_COOKIE, adminTokenCookie("", 0, request.isSecure()).toString());

        return "redirect:/admin/login";
    }

    // Secure 속성은 실제 요청이 HTTPS일 때만 붙인다. — Cloudflare 터널 뒤에서는 X-Forwarded-Proto로 https가 되고,
    // 학교 내부망 http://서버IP:8085 로 직접 접속해 점검할 때도 로그인이 되도록 한다.
    private ResponseCookie adminTokenCookie(String value, long maxAgeSeconds, boolean secure) {
        return ResponseCookie.from(ADMIN_TOKEN_COOKIE, value)
                .httpOnly(true)
                .secure(secure)
                .sameSite("Strict")
                .path(ADMIN_COOKIE_PATH)
                .maxAge(maxAgeSeconds)
                .build();
    }

    // index 처리
    @GetMapping({"", "/", "/index"})
    public String index(Model model) {
        model.addAttribute("dashboard", adminDashboardService.getDashboard());
        return "admin/index";
    }

    // user List 처리
    @GetMapping("/users")
    public String userList(Model model) {
        model.addAttribute("users", adminService.getAllUsers());
        return "admin/user/list";
    }

    // user Detail 처리
    @GetMapping("/users/{id}")
    public String userDetail(@PathVariable Long id, Model model) {
        var user = adminService.getUser(id);

        if (user == null) {
            return "redirect:/admin/users";
        }

        model.addAttribute("user", user);
        return "admin/user/detail";
    }

    // toggle User Role 처리
    @PostMapping("/users/{id}/toggle-role")
    public String toggleUserRole(
            @PathVariable Long id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            adminService.toggleUserRole(userDetails.getUserId(), id);
        } catch (IllegalArgumentException | IllegalStateException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/users";
    }

    // delete User 삭제
    @PostMapping("/users/{id}/delete")
    public String deleteUser(
            @PathVariable Long id,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            RedirectAttributes redirectAttributes
    ) {
        try {
            adminService.deleteUser(userDetails.getUserId(), id);
        } catch (IllegalArgumentException | IllegalStateException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/users";
    }

    // plant List 처리
    @GetMapping("/plants")
    public String plantList(Model model) {
        model.addAttribute("plants", adminService.getAllPlants());
        return "admin/plant/list";
    }

    // create Plant Form 생성
    @GetMapping("/plants/new")
    public String createPlantForm(Model model) {
        model.addAttribute("plantDto", new AdminDto.CreatePlantReqDto());
        return "admin/plant/create";
    }

    // create Plant 생성
    @PostMapping("/plants")
    public String createPlant(
            @Valid @ModelAttribute("plantDto") AdminDto.CreatePlantReqDto plantDto,
            BindingResult bindingResult,
            Model model
    ) {
        String validationError = firstError(bindingResult);

        try {
            if (validationError != null) {
                throw new IllegalArgumentException(validationError);
            }

            adminService.createPlant(plantDto);
            return "redirect:/admin/plants";
        } catch (Exception e) {
            model.addAttribute("errorMessage", toFormErrorMessage(e));
            model.addAttribute("plantDto", plantDto);
            return "admin/plant/create";
        }
    }

    // item List 처리
    @GetMapping("/items")
    public String itemList(Model model) {
        model.addAttribute("items", adminService.getAllItems());
        return "admin/item/list";
    }

    // create Item Form 생성
    @GetMapping("/items/new")
    public String createItemForm(Model model) {
        model.addAttribute("itemDto", new AdminDto.CreateItemReqDto());
        model.addAttribute("itemTypes", ItemType.values());
        return "admin/item/create";
    }

    // create Item 생성
    @PostMapping("/items")
    public String createItem(
            @Valid @ModelAttribute("itemDto") AdminDto.CreateItemReqDto itemDto,
            BindingResult bindingResult,
            Model model
    ) {
        String validationError = firstError(bindingResult);

        try {
            if (validationError != null) {
                throw new IllegalArgumentException(validationError);
            }

            adminService.createItem(itemDto);
            return "redirect:/admin/items";
        } catch (Exception e) {
            model.addAttribute("errorMessage", toFormErrorMessage(e));
            model.addAttribute("itemDto", itemDto);
            model.addAttribute("itemTypes", ItemType.values());
            return "admin/item/create";
        }
    }

    // quest List 처리
    @GetMapping("/quests")
    public String questList(Model model) {
        model.addAttribute("quests", adminService.getAllQuests());
        return "admin/quest/list";
    }

    // create Quest Form 생성
    @GetMapping("/quests/new")
    public String createQuestForm(Model model) {
        model.addAttribute("questDto", new AdminDto.CreateQuestReqDto());
        model.addAttribute("questTypes", QuestType.values());
        model.addAttribute("targetTypes", TargetType.values());
        model.addAttribute("resetCycles", ResetCycle.values());
        return "admin/quest/create";
    }

    // create Quest 생성
    @PostMapping("/quests")
    public String createQuest(
            @Valid @ModelAttribute("questDto") AdminDto.CreateQuestReqDto questDto,
            BindingResult bindingResult,
            Model model
    ) {
        String validationError = firstError(bindingResult);

        try {
            if (validationError != null) {
                throw new IllegalArgumentException(validationError);
            }

            adminService.createQuest(questDto);
            return "redirect:/admin/quests";
        } catch (Exception e) {
            model.addAttribute("errorMessage", toFormErrorMessage(e));
            model.addAttribute("questDto", questDto);
            model.addAttribute("questTypes", QuestType.values());
            model.addAttribute("targetTypes", TargetType.values());
            model.addAttribute("resetCycles", ResetCycle.values());
            return "admin/quest/create";
        }
    }

    // iot List 처리
    @GetMapping("/iot")
    public String iotList(Model model) {
        model.addAttribute("devices", adminService.getAllIotDevices());
        return "admin/iot/list";
    }

    // create Iot Form 생성
    @GetMapping("/iot/new")
    public String createIotForm(Model model) {
        model.addAttribute("iotDto", new AdminDto.CreateIotDeviceReqDto());
        model.addAttribute("deviceTypes", DeviceType.values());
        return "admin/iot/create";
    }

    // create Iot 생성
    @PostMapping("/iot")
    public String createIot(
            @Valid @ModelAttribute("iotDto") AdminDto.CreateIotDeviceReqDto iotDto,
            BindingResult bindingResult,
            Model model
    ) {
        String validationError = firstError(bindingResult);

        try {
            if (validationError != null) {
                throw new IllegalArgumentException(validationError);
            }

            adminService.createIotDevice(iotDto);
            return "redirect:/admin/iot";
        } catch (Exception e) {
            model.addAttribute("errorMessage", toFormErrorMessage(e));
            model.addAttribute("iotDto", iotDto);
            model.addAttribute("deviceTypes", DeviceType.values());
            return "admin/iot/create";
        }
    }

    // 폼 검증 오류 중 첫 번째 메시지 — 타입 변환 실패(숫자 칸에 문자 등)도 사람이 읽을 수 있게 바꾼다.
    private String firstError(BindingResult bindingResult) {
        if (!bindingResult.hasErrors()) {
            return null;
        }

        FieldError fieldError = bindingResult.getFieldError();

        if (fieldError == null) {
            return "입력값을 확인해주세요.";
        }

        if (fieldError.isBindingFailure()) {
            return fieldError.getField() + " 값의 형식이 올바르지 않습니다.";
        }

        return fieldError.getDefaultMessage();
    }

    // 사용자에게 보여줄 오류 메시지 — 예상한 검증 오류만 그대로 보여주고, 나머지(DB 오류 등)는 감춘다.
    private String toFormErrorMessage(Exception e) {
        if (e instanceof IllegalArgumentException || e instanceof IllegalStateException) {
            return e.getMessage();
        }

        log.error("[ADMIN] 관리자 폼 저장 실패", e);
        return "저장 중 오류가 발생했습니다. 입력값을 확인한 뒤 다시 시도해주세요.";
    }
}
