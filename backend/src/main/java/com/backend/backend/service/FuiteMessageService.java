package com.backend.backend.service;

import com.backend.backend.dto.fuite_message.FuiteMessageRequestDto;
import com.backend.backend.dto.fuite_message.FuiteMessageResponseDto;
import java.util.List;

public interface FuiteMessageService {

    FuiteMessageResponseDto createMessage(FuiteMessageRequestDto dto);

    List<FuiteMessageResponseDto> getMessagesByFuite(Long fuiteId);

    void deleteMessage(Long id);
}
