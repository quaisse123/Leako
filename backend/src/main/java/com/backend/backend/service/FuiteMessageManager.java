package com.backend.backend.service;

import com.backend.backend.dao.entities.Fuite;
import com.backend.backend.dao.entities.FuiteMessage;
import com.backend.backend.dao.repositories.FuiteMessageRepository;
import com.backend.backend.dao.repositories.FuiteRepository;
import com.backend.backend.dto.fuite_message.FuiteMessageRequestDto;
import com.backend.backend.dto.fuite_message.FuiteMessageResponseDto;
import com.backend.backend.mapper.FuiteMessageMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FuiteMessageManager implements FuiteMessageService {

    private final FuiteMessageRepository fuiteMessageRepository;
    private final FuiteRepository fuiteRepository;
    private final FuiteMessageMapper fuiteMessageMapper;

    @Override
    @Transactional
    public FuiteMessageResponseDto createMessage(FuiteMessageRequestDto dto) {
        Fuite fuite = fuiteRepository.findById(dto.getFuiteId())
                .orElseThrow(() -> new RuntimeException("Fuite non trouvée avec l'ID : " + dto.getFuiteId()));

        FuiteMessage message = fuiteMessageMapper.toEntity(dto);
        message.setFuite(fuite);
        message.setDateEnvoi(new Date());

        message = fuiteMessageRepository.save(message);
        return fuiteMessageMapper.toDto(message);
    }

    @Override
    public List<FuiteMessageResponseDto> getMessagesByFuite(Long fuiteId) {
        return fuiteMessageRepository.findByFuiteIdOrderByDateEnvoiAsc(fuiteId).stream()
                .map(fuiteMessageMapper::toDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void deleteMessage(Long id) {
        if (!fuiteMessageRepository.existsById(id)) {
            throw new RuntimeException("Message non trouvé avec l'ID : " + id);
        }
        fuiteMessageRepository.deleteById(id);
    }
}
