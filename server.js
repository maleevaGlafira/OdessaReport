const path = require("path");
const express = require("express");
const config = require("./src/config/configLoader");
const apiRoutes = require("./src/routes/apiRoutes");
const openBrowser = require("./src/utils/openBrowser");

const app = express();

// Middleware для JSON и статических файлов
app.use(express.json());

app.use(express.static(path.join(__dirname, "public")));

// Подключение роутов API
app.use("/api", apiRoutes);

// Запуск сервера
app.listen(config.port, () => {
  const url = `http://localhost:${config.port}`;
  console.log(`Сервер успешно запущен на ${url}`);

  // Автоматическое открытие браузера
  openBrowser(url);
});
