class PagesController < ApplicationController
  def home
    @featured = Product.active.featured.ordered.includes(:brand).limit(4)
    @best_sellers = Product.active.best_sellers.ordered.includes(:brand).limit(6)
    @categories = Category.ordered
    @brands = Brand.order(:name)
  end

  def about
    @brands = Brand.order(:name)
  end

  def contact
  end

  # The public contact form. No mailer is configured yet, so the message is
  # logged and the visitor gets a confirmation — wire up ActionMailer to
  # actually deliver it.
  def send_message
    Rails.logger.info("[contact] #{params[:name]} <#{params[:email]}>: #{params[:message]}")
    redirect_to contact_path, notice: "Благодарим! Съобщението е получено — ще се свържем с вас скоро."
  end

  def faq
    @faqs = FAQS
  end

  def privacy
  end

  FAQS = [
    {
      q: "Откъде произлизат продуктите, които предлагате?",
      a: "Ние сме официални вносители за България на продуктите ERA Professional, Turbopax и Power1. Всички артикули са оригинални и идват директно от производителите – Sabuncuoğlu Kimya San. ve Tic. A.Ş. и Turbopax Kimya San. ve Tic. A.Ş., Турция.",
    },
    {
      q: "Могат ли продуктите ERA Professional да се използват в домашни условия?",
      a: "ERA Professional препаратите са разработени основно за професионална употреба във фабрики за пране на килими. В домашни условия те могат да бъдат използвани, но е важно да се спазват инструкциите за разреждане и безопасност.",
    },
    {
      q: "Подходящ ли е Power1 за употреба извън индустрията?",
      a: "Да. Power1 е многофункционален почистващ спрей с разтворители, който е ефективен както за автомобили, така и за домакински уреди, инструменти, кухни, гаражи и други повърхности.",
    },
    {
      q: "Какво прави Turbopax предпочитан избор за автомивки?",
      a: "Шампоаните Turbopax образуват гъста пяна, разграждат бързо мръсотията и се изплакват лесно, което ги прави подходящи за самообслужващи се автомивки и професионални обекти.",
    },
    {
      q: "Доставяте ли продуктите в цялата страна?",
      a: "Да. Доставяме бързо в цялата страна чрез куриерски услуги в рамките на 1–3 работни дни в зависимост от локацията.",
    },
    {
      q: "Могат ли продуктите да се закупят и на едро?",
      a: "Освен онлайн продажби на дребно, предлагаме и партньорства на едро. Свържете се директно с нас за оферта.",
    },
    {
      q: "Как да избера правилния продукт за моите нужди?",
      a: "Ако не сте сигурни кой продукт е подходящ за вас, свържете се с екипа ни за професионална консултация.",
    },
  ].freeze
end
