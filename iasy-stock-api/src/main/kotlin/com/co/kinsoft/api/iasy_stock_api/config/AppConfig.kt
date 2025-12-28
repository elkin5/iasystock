package com.co.kinsoft.api.iasy_stock_api.config

import org.springframework.context.annotation.ComponentScan
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.FilterType

@Configuration
@ComponentScan(
    basePackages = ["com.co.kinsoft.api.iasy_stock_api.domain.usecase"],
    includeFilters = [ComponentScan.Filter(type = FilterType.REGEX, pattern = arrayOf("^.+UseCase$"))],
    useDefaultFilters = false
)
class AppConfig