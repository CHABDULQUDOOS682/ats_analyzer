// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:submit-start", (event) => {
    const form = event.target;
    if (form.dataset.loader === "true") {
        const loader = document.getElementById("loader");
        if (loader) loader.style.display = "flex";
    }
});

document.addEventListener("turbo:submit-end", () => {
    const loader = document.getElementById("loader");
    if (loader) loader.style.display = "none";
});
