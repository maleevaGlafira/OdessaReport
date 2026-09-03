const fs = require("fs");
const path = require("path");
const Firebird = require("node-firebird");
const config = require("../config/configLoader");

const queryPath = path.join(__dirname, "../queries/report.sql");
const sqlQuery = fs.readFileSync(queryPath, "utf8");

// Надежное чтение BLOB из stream
function fetchBlobText(db, blobFn) {
  return new Promise((resolve) => {
    if (typeof blobFn !== "function") {
      return resolve(blobFn ? String(blobFn) : "");
    }

    blobFn((err, name, stream) => {
      if (err || !stream) return resolve("");

      // Принудительно запрашиваем чтение блоба через встроенный хэндлер драйвера
      let buffer = Buffer.alloc(0);

      stream.on("data", (chunk) => {
        buffer = Buffer.concat([buffer, chunk]);
        console.log(`Получено ${buffer.length} байт данных из BLOB`);
      });

      stream.on("end", () => {
        resolve(buffer.toString("utf8").trim());
      });

      stream.on("error", () => resolve(""));

      // Если поток «завис» и не генерирует события, делаем resume
      if (stream.resume) {
        stream.resume();
      }
    });
  });
}

function executeReport(params) {
  return new Promise((resolve, reject) => {
    const { prinad1, prinad2, dt_begin, dt_finish, numbers } = params;

    const dtBeginFormatted = dt_begin.replace("T", " ") + ":00";
    const dtFinishFormatted = dt_finish.replace("T", " ") + ":00";

    const queryParams = [
      prinad1,
      prinad2,
      dtBeginFormatted,
      dtFinishFormatted,
      prinad1,
      prinad2,
      dtBeginFormatted,
      dtFinishFormatted,
      numbers,
      prinad1,
      prinad2,
      dtBeginFormatted,
      dtFinishFormatted,
      prinad1,
      prinad2,
      dtBeginFormatted,
      dtFinishFormatted,
    ];

    Firebird.attach(config.db, (err, db) => {
      if (err) return reject(err);

      db.query(sqlQuery, queryParams, async (queryErr, result) => {
        if (queryErr) {
          db.detach();
          return reject(queryErr);
        }

        try {
          // Последовательно вычитываем BLOB для каждого поля
          const processedRows = [];
          for (const row of result) {
            const newRow = {};
            for (const key of Object.keys(row)) {
              if (typeof row[key] === "function") {
                newRow[key] = await fetchBlobText(db, row[key]);
              } else {
                newRow[key] = row[key];
              }
            }
            processedRows.push(newRow);
          }

          db.detach();
          resolve(processedRows);
        } catch (procErr) {
          db.detach();
          reject(procErr);
        }
      });
    });
  });
}

module.exports = { executeReport };
