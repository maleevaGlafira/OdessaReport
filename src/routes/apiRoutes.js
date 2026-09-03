const express = require("express");
const router = express.Router();
const { executeReport } = require("../services/firebirdService");
const { generateExcel } = require("../services/excelService");

// Кэш последнего запроса в памяти для быстрой выгрузки в Excel
let lastQueryResult = [];

// 1. Запрос данных для таблицы
router.post("/query", async (req, res) => {
  try {
    const data = await executeReport(req.body);
    lastQueryResult = data; // Сохраняем в память
    res.json({ success: true, count: data.length, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Скачивание текущего результата в Excel
router.get("/download-excel", async (req, res) => {
  try {
    if (!lastQueryResult.length) {
      return res
        .status(400)
        .send("Нет данных для экспорта. Сначала выполните запрос.");
    }

    const buffer = await generateExcel(lastQueryResult);
    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );
    res.setHeader(
      "Content-Disposition",
      'attachment; filename="firebird_report.xlsx"',
    );
    res.send(buffer);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

module.exports = router;
