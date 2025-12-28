package com.co.kinsoft.api.iasy_stock_api.domain.common

fun isValidEmail(email: String): Boolean {
    val emailRegex = Regex("^([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+)$")
    return emailRegex.matches(email)
}

fun isValidWebsite(website: String): Boolean {
    val websiteRegex = Regex("^(http(s)?://)?[\\w.-]+(\\.[\\w.-]+)+(/[\\w-]+)*(/)?$")
    return websiteRegex.matches(website)
}