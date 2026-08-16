(function () {
  const buttons = document.querySelectorAll("[data-set-lang]");
  const blocks = document.querySelectorAll("[data-lang]");
  const params = new URLSearchParams(location.search);
  const stored = localStorage.getItem("notis-lang");
  const requested = params.get("lang") || stored || "de";
  const lang = requested.toLowerCase().startsWith("en") ? "en" : "de";

  function apply(next) {
    localStorage.setItem("notis-lang", next);
    document.documentElement.lang = next;
    blocks.forEach((el) => {
      el.hidden = el.getAttribute("data-lang") !== next;
    });
    buttons.forEach((btn) => {
      btn.setAttribute("aria-pressed", String(btn.getAttribute("data-set-lang") === next));
    });
  }

  buttons.forEach((btn) => {
    btn.addEventListener("click", () => apply(btn.getAttribute("data-set-lang")));
  });
  apply(lang);
})();
