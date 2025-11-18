import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="locale-suggestion"
export default class extends Controller {
  static targets = ["banner", "messageText", "switchButton", "dismissButton"]
  static values = {
    currentLocale: String,
    apiUrl: String,
    dismissedKey: String,
    translations: Object
  }

  // Language to locale mapping with country preferences
  static languageToLocaleMap = {
    'en': ['en'],
    'ja': ['ja'],
    'zh': ['zh-CN'],
    'zh-CN': ['zh-CN'],
    'zh-TW': ['zh-CN'], // Fallback to simplified Chinese
    'es': ['es'],
    'fr': ['fr'],
    'hi': ['hi'],
    'ar': ['ar']
  }

  // Country to preferred locale mapping (ISO 3166-1 alpha-2)
  static countryToLocaleMap = {
    // English
    'US': 'en', 'GB': 'en', 'AU': 'en', 'CA': 'en', 'NZ': 'en', 'IE': 'en',

    // Japanese
    'JP': 'ja',

    // Chinese
    'CN': 'zh-CN', 'SG': 'zh-CN', 'MY': 'zh-CN', 'TW': 'zh-CN',

    // Spanish
    'ES': 'es', 'MX': 'es', 'AR': 'es', 'CO': 'es', 'PE': 'es', 'VE': 'es',
    'CL': 'es', 'EC': 'es', 'BO': 'es', 'PY': 'es', 'UY': 'es', 'CR': 'es',
    'PA': 'es', 'SV': 'es', 'HN': 'es', 'NI': 'es', 'GT': 'es', 'DO': 'es',
    'CU': 'es', 'PR': 'es',

    // French
    'FR': 'fr', 'BE': 'fr', 'CH': 'fr', 'LU': 'fr', 'MC': 'fr',

    // Hindi
    'IN': 'hi',

    // Arabic
    'SA': 'ar', 'AE': 'ar', 'EG': 'ar', 'MA': 'ar', 'TN': 'ar', 'DZ': 'ar',
    'LY': 'ar', 'SD': 'ar', 'IQ': 'ar', 'SY': 'ar', 'LB': 'ar', 'JO': 'ar',
    'KW': 'ar', 'QA': 'ar', 'BH': 'ar', 'OM': 'ar', 'YE': 'ar'
  }

  connect() {
    // Only show suggestion on the landing page
    if (!this.isLandingPage()) return

    // Check if user has already dismissed the suggestion
    if (this.isDismissed()) return

    // Check if user already has a preferred locale set
    if (this.hasUserPreference()) return

    // Detect suggested locale and show banner if different
    this.detectAndSuggestLocale()
  }

  async detectAndSuggestLocale() {
    try {
      const suggestedLocale = await this.detectBestLocale()

      if (suggestedLocale && suggestedLocale !== this.currentLocaleValue) {
        this.showSuggestionBanner(suggestedLocale)
      }
    } catch (error) {
      console.log('Locale detection failed:', error)
      // Silently fail - locale suggestion is not critical
    }
  }

  async detectBestLocale() {
    // Try geographic detection first (more accurate for region-specific content)
    const geoLocale = await this.detectLocaleByGeography()
    if (geoLocale) return geoLocale

    // Fallback to browser language detection
    return this.detectLocaleByLanguage()
  }

  async detectLocaleByGeography() {
    try {
      // Use a public IP geolocation service
      const response = await fetch('https://ipapi.co/json/', {
        timeout: 3000 // 3 second timeout
      })

      if (!response.ok) throw new Error('Geo API failed')

      const data = await response.json()
      const countryCode = data.country_code

      if (countryCode && this.constructor.countryToLocaleMap[countryCode]) {
        return this.constructor.countryToLocaleMap[countryCode]
      }
    } catch (error) {
      console.log('Geographic detection failed:', error)
      return null
    }
  }

  detectLocaleByLanguage() {
    // Get browser languages in order of preference
    const languages = navigator.languages || [navigator.language || navigator.userLanguage]

    for (const lang of languages) {
      // Try exact match first (e.g., 'zh-CN')
      if (this.constructor.languageToLocaleMap[lang]) {
        return this.constructor.languageToLocaleMap[lang][0]
      }

      // Try language prefix (e.g., 'zh' from 'zh-CN')
      const langPrefix = lang.split('-')[0]
      if (this.constructor.languageToLocaleMap[langPrefix]) {
        return this.constructor.languageToLocaleMap[langPrefix][0]
      }
    }

    return null
  }

  showSuggestionBanner(suggestedLocale) {
    // Get translations for the suggested locale
    const translations = this.translationsValue[suggestedLocale]
    if (!translations) {
      console.warn(`No translations found for locale: ${suggestedLocale}`)
      return
    }

    // Get native language names
    const suggestedLanguageName = this.getNativeLocaleName(suggestedLocale)
    const currentLanguageName = this.getNativeLocaleName(this.currentLocaleValue)

    // Build message in the suggested language
    const message = `
      <strong>${translations.title}</strong>
      ${translations.switch_to.replace('__LANGUAGE__', `<span class="fw-bold text-primary">${suggestedLanguageName}</span>`)}
      <small class="text-muted d-block">
        ${translations.currently_viewing.replace('__CURRENT__', currentLanguageName)}
      </small>
    `

    // Update banner content
    this.messageTextTarget.innerHTML = message
    this.switchButtonTarget.textContent = translations.switch_button

    // Stay button should be in the current locale's native language
    const currentTranslations = this.translationsValue[this.currentLocaleValue]
    this.dismissButtonTarget.textContent = currentTranslations ? currentTranslations.stay_button : 'Stay'

    // Set up switch button
    this.switchButtonTarget.onclick = () => this.switchToLocale(suggestedLocale)

    // Show banner with animation
    this.bannerTarget.style.display = 'block'
    setTimeout(() => {
      this.bannerTarget.style.opacity = '1'
      this.bannerTarget.style.transform = 'translateY(0)'
    }, 100)
  }

  switchToLocale(locale) {
    // Create and submit form to switch locale
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/switch_locale'

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add locale parameter
    const localeInput = document.createElement('input')
    localeInput.type = 'hidden'
    localeInput.name = 'locale'
    localeInput.value = locale
    form.appendChild(localeInput)

    // Submit form
    document.body.appendChild(form)
    form.submit()
  }

  dismiss() {
    // Store dismissal in localStorage
    localStorage.setItem(this.dismissedKeyValue, 'true')

    // Hide banner with animation
    this.bannerTarget.style.opacity = '0'
    this.bannerTarget.style.transform = 'translateY(-100%)'

    setTimeout(() => {
      this.bannerTarget.style.display = 'none'
    }, 300)
  }

  // Helper methods
  isLandingPage() {
    return window.location.pathname === '/' || window.location.pathname === '/landing'
  }

  isDismissed() {
    return localStorage.getItem(this.dismissedKeyValue) === 'true'
  }

  hasUserPreference() {
    // Check if user has a stored locale preference in session/cookie
    return document.cookie.includes('locale=') || sessionStorage.getItem('locale')
  }

  getNativeLocaleName(locale) {
    // Always return language names in their native language
    const names = {
      'en': 'English',
      'ja': '日本語',
      'zh-CN': '中文',
      'es': 'Español',
      'fr': 'Français',
      'hi': 'हिन्दी',
      'ar': 'العربية'
    }
    return names[locale] || locale
  }

  // Deprecated: kept for backwards compatibility
  getLocaleName(locale) {
    return this.getNativeLocaleName(locale)
  }
}