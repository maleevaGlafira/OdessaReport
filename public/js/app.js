let rawData = [];
let currentPage = 1;
const rowsPerPage = 20;

document.addEventListener("DOMContentLoaded", () => {
  const now = new Date();
  const defaultDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}T00:00`;
  document.getElementById("dt_begin").value = defaultDate;
  document.getElementById("dt_finish").value = defaultDate;
});

document.getElementById("reportForm").addEventListener("submit", async (e) => {
  e.preventDefault();

  const submitBtn = document.getElementById("submitBtn");
  const excelBtn = document.getElementById("excelBtn");
  const status = document.getElementById("status");

  submitBtn.disabled = true;
  excelBtn.disabled = true;
  status.style.color = "#333";
  status.textContent = "Выполнение SQL-запроса к Firebird...";

  const payload = {
    prinad1: parseInt(document.getElementById("prinad1").value, 10),
    prinad2: parseInt(document.getElementById("prinad2").value, 10),
    dt_begin: document.getElementById("dt_begin").value,
    dt_finish: document.getElementById("dt_finish").value,
    numbers: parseInt(document.getElementById("numbers").value, 10),
  };

  try {
    const res = await fetch("/api/query", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const result = await res.json();
    if (!res.ok) throw new Error(result.error);

    rawData = result.data;
    console.log("Полученные данные:", rawData);
    currentPage = 1;

    status.style.color = "green";
    status.textContent = `Успешно получено записей: ${result.count}`;

    excelBtn.disabled = false;
    renderTable();
  } catch (err) {
    status.style.color = "red";
    status.textContent = err.message;
  } finally {
    submitBtn.disabled = false;
  }
});

// Кнопка выгрузки Excel
document.getElementById("excelBtn").addEventListener("click", () => {
  window.location.href = "/api/download-excel";
});

// Отрисовка страницы таблицы
function renderTable() {
  const resultCard = document.getElementById("resultCard");
  const tbody = document.querySelector("#dataTable tbody");

  resultCard.style.display = "block";
  tbody.innerHTML = "";

  document.getElementById("totalRows").textContent = rawData.length;
  const totalPages = Math.ceil(rawData.length / rowsPerPage) || 1;
  document.getElementById("totalPages").textContent = totalPages;
  document.getElementById("currentPage").textContent = currentPage;

  const start = (currentPage - 1) * rowsPerPage;
  const pageData = rawData.slice(start, start + rowsPerPage);

  pageData.forEach((row) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
            <td>${row.NOMER_2 || ""}</td>
            <td>${row.DT_IN ? new Date(row.DT_IN).toLocaleString() : ""}</td>
            <td>${row.NAME_R || ""}</td>
            <td>${row.F_1 || ""}</td>
            <td>${row.NAME_R1 || ""}</td>
            <td>${row.NAME_2 || ""}</td>
            <td>${row.COL_V || 0}</td>
            <td>${row.COUN || 0}</td>
            <td>${row.DOP_INF || ""}</td>
        `;
    tbody.appendChild(tr);
  });

  document.getElementById("prevPage").disabled = currentPage === 1;
  document.getElementById("nextPage").disabled = currentPage === totalPages;
}

document.getElementById("prevPage").addEventListener("click", () => {
  if (currentPage > 1) {
    currentPage--;
    renderTable();
  }
});

document.getElementById("nextPage").addEventListener("click", () => {
  const totalPages = Math.ceil(rawData.length / rowsPerPage);
  if (currentPage < totalPages) {
    currentPage++;
    renderTable();
  }
});
