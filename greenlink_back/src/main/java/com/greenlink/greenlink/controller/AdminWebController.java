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
import com.greenlink.greenlink.service.AdminService;
import com.greenlink.greenlink.service.AuthService;
import com.greenlink.greenlink.service.UserService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

// 관리자 Thymeleaf Controller — 웹 화면
@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminWebController {

    // 관리자 JWT cookie — /admin 경로에서만 전송되고 JS에서 읽을 수 없다.
    public static final String ADMIN_TOKEN_COOKIE = "jwt_token";
    private static final String ADMIN_COOKIE_PATH = "/admin";
    private static final long ADMIN_COOKIE_MAX_AGE_SECONDS = 86400;

    private final AdminService adminService;
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
                adminTokenCookie(loginResult.getAccessToken(), ADMIN_COOKIE_MAX_AGE_SECONDS).toString()
        );

        return "redirect:/admin";
    }

    // 로그아웃 — tokenVersion 증가로 기존 JWT 무효화 후 cookie 삭제
    @PostMapping("/logout")
    public String logout(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            HttpServletResponse response
    ) {
        if (userDetails != null) {
            userService.logout(userDetails.getUserId());
        }

        response.addHeader(HttpHeaders.SET_COOKIE, adminTokenCookie("", 0).toString());

        return "redirect:/admin/login";
    }

    private ResponseCookie adminTokenCookie(String value, long maxAgeSeconds) {
        return ResponseCookie.from(ADMIN_TOKEN_COOKIE, value)
                .httpOnly(true)
                .secure(true)
                .sameSite("Strict")
                .path(ADMIN_COOKIE_PATH)
                .maxAge(maxAgeSeconds)
                .build();
    }

    // index 처리
    @GetMapping({"", "/", "/index"})
    public String index() {
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
        model.addAttribute("user", adminService.getUser(id));
        return "admin/user/detail";
    }

    // toggle User Role 처리
    @PostMapping("/users/{id}/toggle-role")
    public String toggleUserRole(@PathVariable Long id) {
        adminService.toggleUserRole(id);
        return "redirect:/admin/users";
    }

    // delete User 삭제
    @PostMapping("/users/{id}/delete")
    public String deleteUser(@PathVariable Long id) {
        adminService.deleteUser(id);
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
    public String createPlant(@ModelAttribute AdminDto.CreatePlantReqDto plantDto, Model model) {
        try {
            adminService.createPlant(plantDto);
            return "redirect:/admin/plants";
        } catch (Exception e) {
            model.addAttribute("errorMessage", e.getMessage());
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
    public String createItem(@ModelAttribute AdminDto.CreateItemReqDto itemDto, Model model) {
        try {
            adminService.createItem(itemDto);
            return "redirect:/admin/items";
        } catch (Exception e) {
            model.addAttribute("errorMessage", e.getMessage());
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
    public String createQuest(@ModelAttribute AdminDto.CreateQuestReqDto questDto, Model model) {
        try {
            adminService.createQuest(questDto);
            return "redirect:/admin/quests";
        } catch (Exception e) {
            model.addAttribute("errorMessage", e.getMessage());
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
    public String createIot(@ModelAttribute AdminDto.CreateIotDeviceReqDto iotDto, Model model) {
        try {
            adminService.createIotDevice(iotDto);
            return "redirect:/admin/iot";
        } catch (Exception e) {
            model.addAttribute("errorMessage", e.getMessage());
            model.addAttribute("iotDto", iotDto);
            model.addAttribute("deviceTypes", DeviceType.values());
            return "admin/iot/create";
        }
    }
}
