const ExcelJS = require("exceljs");

async function generateExcel(data) {
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet("Отчет");

  // Заголовки колонок
  worksheet.columns = [
    { header: "Номер", key: "NOMER_2", width: 12 },
    { header: "Дата/Время", key: "DT_IN", width: 20 },
    { header: "Район", key: "NAME_R", width: 20 },
    { header: "Адрес", key: "F_1", width: 35 },
    { header: "Владелец", key: "NAME_R1", width: 20 },
    { header: "Содержание", key: "NAME_2", width: 25 },
    { header: "Кол-во выездов", key: "COL_V", width: 15 },
    { header: "Всего по адресу", key: "COUN", width: 15 },
    { header: "Доп. информация", key: "DOP_INF", width: 50 },
  ];

  // Стилизация заголовка
  worksheet.getRow(1).font = { bold: true };
  worksheet.getRow(1).fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "FFE0E0E0" },
  };

  // Заполнение данными
  data.forEach((row) => worksheet.addRow(row));

  return await workbook.xlsx.writeBuffer();
}

module.exports = { generateExcel };
