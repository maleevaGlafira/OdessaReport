const path = require("path");
const dotenv = require("dotenv");

// Определяем путь к папке, где находится исполняемый файл или main скрипт
const basePath = process.pkg ? path.dirname(process.execPath) : process.cwd();

// Загружаем .env файл из папки запуска
dotenv.config({ path: path.join(basePath, ".env") });

module.exports = {
  port: process.env.PORT || 3000,
  db: {
    host: process.env.DB_HOST || "127.0.0.1",
    port: parseInt(process.env.DB_PORT, 10) || 3050,
    database: process.env.DB_PATH || "",
    user: process.env.DB_USER || "SYSDBA",
    password: process.env.DB_PASSWORD || "masterkey",
    charset: process.env.DB_CHARSET || "UTF8",
  },
};
