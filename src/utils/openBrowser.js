const open = require("open");

function openBrowser(url) {
  open(url).catch((err) => {
    console.error("Не удалось автоматически открыть браузер:", err.message);
  });
}

module.exports = openBrowser;
