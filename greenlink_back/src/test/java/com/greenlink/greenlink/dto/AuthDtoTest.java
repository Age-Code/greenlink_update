package com.greenlink.greenlink.dto;

import com.greenlink.greenlink.domain.item.Item;
import com.greenlink.greenlink.domain.item.UserItem;
import com.greenlink.greenlink.domain.user.User;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

class AuthDtoTest {

    @Test
    void grantedItemContainsBothUserItemIdAndItemId() {
        User user = User.createUser("user@example.com", "encoded-password", "user");
        Item item = Item.createPot("기본 화분", null, null);
        ReflectionTestUtils.setField(item, "id", 51L);
        UserItem userItem = UserItem.createOwned(user, item);
        ReflectionTestUtils.setField(userItem, "id", 61L);

        AuthDto.GrantedItemDto dto = AuthDto.GrantedItemDto.from(userItem);

        assertThat(dto.getUserItemId()).isEqualTo(61L);
        assertThat(dto.getItemId()).isEqualTo(51L);
    }
}
