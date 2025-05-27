/* helper functions */
function getAge(dateStr) {
  const today = new Date(),
    dob = new Date(dateStr);
  let a = today.getFullYear() - dob.getFullYear();
  const m = today.getMonth() - dob.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) a--;
  return a;
}

function makeTable(headers) {
  const t = document.createElement("table");
  const tr = document.createElement("tr");
  headers.forEach((h) => {
    const th = document.createElement("th");
    th.textContent = h;
    tr.appendChild(th);
  });
  t.appendChild(tr);
  return t;
}

function showError(e) {
  content.innerHTML = `<div class="alert">${e.error || e}</div>`;
}

/* API */
const API_BASE = "http://localhost:8000/api/v1";

const api = {
  // 1. List all users
  listUsers: async () => {
    const res = await fetch(`${API_BASE}/users`);
    if (!res.ok) throw new Error(`Error ${res.status}`);
    return res.json();
    // -> { users: [...] }
  },

  // 2. Get one user’s profile + latest biomarkers
  getUserProfile: async (userId) => {
    const res = await fetch(`${API_BASE}/users/${userId}/profile`);
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error(err?.detail || `Error ${res.status}`);
    }
    return res.json();
    // -> { user: {...}, biomarkers: [...] }
  },

  // 3. Get current bio-age results
  getBioAge: async (userId) => {
    const res = await fetch(`${API_BASE}/users/${userId}/bio-age`);
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error(err?.detail || `Error ${res.status}`);
    }
    return res.json();
    // -> { bioAges: [...] }
  },

  // 3.5 Calculate + persist bio-age
  calculateBioAge: async (userId, modelName = "") => {
    const res = await fetch(`${API_BASE}/users/${userId}/bio-age/calculate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ modelName }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error(err?.detail || `Error ${res.status}`);
    }
    return res.json();
    // -> { calculations: [...] }
  },

  // 4. Add a new measurement session + its measurements
  addMeasurements: async (
    userId,
    { sessionDate, fastingStatus, measurements }
  ) => {
    const res = await fetch(`${API_BASE}/users/${userId}/measurements`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionDate, fastingStatus, measurements }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error(err?.detail || `Error ${res.status}`);
    }
    return res.json();
    // -> { sessionId, measurementIds: [...] }
  },

  // 5. Reference-range comparison
  compareRanges: async (userId, type = "both") => {
    const res = await fetch(`${API_BASE}/users/${userId}/ranges?type=${type}`);
    if (!res.ok) throw new Error(`Error ${res.status}`);
    return res.json();
    // -> { ranges: [...] }
  },

  // 6. Biomarker trend
  trend: async (userId, biomarkerId, limit = 20, range = "100years") => {
    const params = new URLSearchParams({ limit, range });
    const res = await fetch(
      `${API_BASE}/users/${userId}/biomarkers/${biomarkerId}/trend?${params}`
    );
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error(err?.detail || `Error ${res.status}`);
    }
    return res.json();
    // -> { trend: [...] }
  },

  // 7. Biological-age history
  bioAgeHistory: async (userId, model = "") => {
    const q = model ? `?model=${encodeURIComponent(model)}` : "";
    const res = await fetch(`${API_BASE}/users/${userId}/bio-age/history${q}`);
    if (!res.ok) throw new Error(`Error ${res.status}`);
    return res.json();
    // -> { history: [...] }
  },

  // 8. Session details + measurements
  getSessionDetails: async (userId, sessionId) => {
    const res = await fetch(
      `${API_BASE}/users/${userId}/sessions/${sessionId}`
    );
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error(err?.detail || `Error ${res.status}`);
    }
    return res.json();
    // -> { sessionId, sessionDate, fastingStatus, measurements: [...] }
  },

  // 9. Biomarker catalog
  biomarkerCatalog: async () => {
    const res = await fetch(`${API_BASE}/biomarkers`);
    if (!res.ok) throw new Error(`Error ${res.status}`);
    return res.json();
    // -> { biomarkers: [...] }
  },

  // 10. Ranges for one biomarker
  biomarkerRanges: async (biomarkerId) => {
    const res = await fetch(`${API_BASE}/biomarkers/${biomarkerId}/ranges`);
    if (!res.ok) {
      const err = await res.json().catch(() => null);
      throw new Error(err?.detail || `Error ${res.status}`);
    }
    return res.json();
    // -> { ranges: [...] }
  },

  // 11. Users with session summary
  usersSessionSummary: async () => {
    const res = await fetch(`${API_BASE}/users/session-summary`);
    if (!res.ok) throw new Error(`Error ${res.status}`);
    return res.json();
    // -> { users: [...] }
  },

  // 12. Biomarkers with measurement summary
  biomarkersWithMeasurements: async () => {
    const res = await fetch(`${API_BASE}/biomarkers/measurement-summary`);
    if (!res.ok) throw new Error(`Error ${res.status}`);
    return res.json();
    // -> { biomarkers: [...] }
  },
};

/* UI globals */
const content = document.querySelector("#content");
const runButton = document.querySelector("#runBtn");
let selectedUserId = null;

/* populate user dropdown */
api.listUsers().then((d) => {
  const sel = document.querySelector("#userSelect");
  sel.innerHTML = '<option value="">— select user —</option>';
  d.users.forEach((u) => {
    const opt = document.createElement("option");
    opt.value = u.userId;
    opt.textContent = `${u.userId} — ${u.sex}, age ${u.age}`;
    sel.appendChild(opt);
  });
  sel.addEventListener("change", () => {
    selectedUserId = parseInt(sel.value) || null;
  });
});

function ensureUser() {
  if (!selectedUserId) {
    showError("Select a user first using the dropdown.");
    return false;
  }
  return true;
}

/* Queries */

/* Query 1: list users */
function listUsers() {
  api
    .listUsers()
    .then((data) => {
      content.innerHTML = "<h2>All Users</h2>";
      const t = makeTable([
        "User ID",
        "SEQN",
        "Age",
        "Sex",
        "Race/Ethnicity",
        "Sessions",
      ]);
      data.users.forEach((u) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${u.userId}</td>
          <td>${u.seqn}</td>
          <td>${u.age}</td>
          <td>${u.sex}</td>
          <td>${u.raceEthnicity}</td>
          <td>${u.sessionCount}</td>
        `;
        t.appendChild(tr);
      });
      content.appendChild(t);
    })
    .catch(showError);
}

/* Query 2: user profile */
function userProfile() {
  if (!ensureUser()) return;
  api
    .getUserProfile(selectedUserId)
    .then((d) => {
      content.innerHTML = `
        <h2>User Profile - ${selectedUserId}</h2>
        <p>
          <strong>Age:</strong> ${d.user.age} &nbsp;
          <strong>Sex:</strong> ${d.user.sex} &nbsp;
          <strong>Race/Ethnicity:</strong> ${d.user.raceEthnicity}
        </p>
      `;
      const t = makeTable(["Biomarker", "Value", "Units", "Date"]);
      d.biomarkers.forEach((b) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${b.name}</td>
          <td>${b.value}</td>
          <td>${b.units}</td>
          <td>${b.takenAt}</td>
        `;
        t.appendChild(tr);
      });
      content.appendChild(t);
    })
    .catch(showError);
}

/* Query 3: bio age */
function bioAge() {
  if (!ensureUser()) return;
  api
    .getBioAge(selectedUserId)
    .then((d) => {
      content.innerHTML = `<h2>Biological Age - User ${selectedUserId}</h2>`;
      const t = makeTable(["Model", "Bio Age", "Age Gap", "Computed At"]);
      d.bioAges.forEach((b) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td>${b.modelName}</td><td>${b.bioAgeYears.toFixed(
          1
        )}</td><td>${b.ageGap.toFixed(1)}</td><td>${
          b.computedAt.split("T")[0]
        }</td>`;
        t.appendChild(tr);
      });
      content.appendChild(t);
      content.appendChild(document.createElement("br"));
      for (const modelName of ["Phenotypic Age", "Homeostatic Dysregulation"]) {
        const btn = document.createElement("button");
        btn.textContent = "Recalculate " + modelName;
        btn.onclick = () => {
          api.calculateBioAge(selectedUserId, modelName).then((d) => {
            bioAge();
          });
        };
        content.appendChild(document.createElement("br"));
        content.appendChild(btn);
        content.appendChild(document.createElement("br"));
      }
    })
    .catch(showError);
}

/* Query 4: add measurement */
function addMeasurementsForm() {
  if (!ensureUser()) return;
  content.innerHTML = "";
  const form = document.createElement("div");
  form.className = "form-block";
  form.innerHTML = `<h4>Add Measurement - User ${selectedUserId}</h4>`;
  form.innerHTML += `
    <label class="small">Session Date</label>
    <input type="date" id="sessDate" value="${
      new Date().toISOString().split("T")[0]
    }">
  `;
  form.innerHTML += `
    <label class="small">
      <input type="checkbox" id="fastingChk"> Fasting session
    </label>
  `;
  const table = makeTable(["Biomarker", "Value"]);
  api.biomarkerCatalog().then((cat) => {
    cat.biomarkers.forEach((b) => {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${b.name}</td>
        <td><input type="number" step="0.1" data-bioid="${b.biomarkerId}" style="width:120px;"> ${b.units}</td>
      `;
      table.appendChild(tr);
    });
    form.appendChild(table);
    form.appendChild(document.createElement("br"));
    const btn = document.createElement("button");
    btn.textContent = "Submit";
    btn.onclick = () => {
      const rows = form.querySelectorAll("input[data-bioid]");
      const measurements = [];
      rows.forEach((inp) => {
        if (inp.value != "") {
          measurements.push({
            biomarkerId: parseInt(inp.dataset.bioid),
            value: parseFloat(inp.value),
          });
        }
      });
      if (measurements.length === 0) {
        alert("Enter at least one value");
        return;
      }
      api
        .addMeasurements(selectedUserId, {
          sessionDate: document.querySelector("#sessDate").value,
          fastingStatus: document.querySelector("#fastingChk").checked,
          measurements,
        })
        .then((r) => {
          content.innerHTML = `
            <div class="success">Added session ${r.sessionId} with ${r.measurementIds.length} measurements.</div>`;
        })
        .catch(showError);
    };
    form.appendChild(btn);
    content.appendChild(form);
  });
}

/* Query 5: compare ranges */
function compareRangesForm() {
  if (!ensureUser()) return;
  content.innerHTML = "";
  const form = document.createElement("div");
  form.className = "form-block";
  form.innerHTML = `<h4>Compare Ranges - User ${selectedUserId}</h4>`;
  form.innerHTML += `
    <label class="small">Range Type</label>
    <select id="rangeType">
      <option value="both">Both</option>
      <option value="clinical">Clinical</option>
      <option value="longevity">Longevity</option>
    </select>
  `;
  const btn = document.createElement("button");
  btn.textContent = "Run";
  const results = document.createElement("div");
  btn.onclick = () => {
    api
      .compareRanges(selectedUserId, document.querySelector("#rangeType").value)
      .then((d) => {
        const rangeType = document.querySelector("#rangeType").value;
        results.innerHTML = `<h2>Range Comparison - ${rangeType}</h2>`;
        const t = makeTable([
          "Biomarker",
          "Value",
          "Status",
          "Clinical",
          "Longevity",
        ]);
        d.ranges.forEach((r) => {
          const clinicalRange =
            rangeType != "longevity" && JSON.parse(r.clinicalRange);
          const longevityRange =
            rangeType != "clinical" && JSON.parse(r.longevityRange);
          const tr = document.createElement("tr");
          tr.innerHTML = `<td>${r.name}</td><td>${
            r.value
          }</td><td class="status-${r.status.toLowerCase()}">${
            r.status == "OutOfRange" ? "Out of Range" : r.status
          }</td><td>${
            clinicalRange ? `${clinicalRange.min}-${clinicalRange.max}` : "—"
          }</td><td>${
            longevityRange ? `${longevityRange.min}-${longevityRange.max}` : "—"
          }</td>`;
          t.appendChild(tr);
        });
        results.appendChild(t);
      })
      .catch(showError);
  };
  form.appendChild(btn);
  content.appendChild(form);
  content.appendChild(results);
}

/* Query 6: trend */
function trendForm() {
  if (!ensureUser()) return;
  content.innerHTML = "";
  const form = document.createElement("div");
  form.className = "form-block";
  form.innerHTML = `<h4>Biomarker Trend - User ${selectedUserId}</h4>`;
  api.biomarkerCatalog().then((cat) => {
    const sel = document.createElement("select");
    sel.id = "bioSel";
    cat.biomarkers.forEach((b) => {
      const op = document.createElement("option");
      op.value = b.biomarkerId;
      op.textContent = `${b.biomarkerId} - ${b.name}`;
      sel.appendChild(op);
    });
    form.appendChild(sel);
    form.innerHTML += `
      <label class="small">Number of points</label>
      <input type="number" id="trendLimit" value="10" min="3" max="50">
    `;
    const btn = document.createElement("button");
    btn.textContent = "Run";
    btn.onclick = () => {
      api
        .trend(
          selectedUserId,
          parseInt(sel.value),
          parseInt(document.querySelector("#trendLimit").value)
        )
        .then((d) => {
          content.innerHTML = `<h2>Trend - Biomarker ${sel.value}</h2>`;
          const canvas = document.createElement("canvas");
          canvas.width = 600;
          canvas.height = 300;
          content.appendChild(canvas);
          drawTrend(canvas, d.trend);
          const t = makeTable(["Date", "Value"]);
          d.trend.reverse().forEach((r) => {
            const tr = document.createElement("tr");
            tr.innerHTML = `<td>${r.date}</td><td>${r.value}</td>`;
            t.appendChild(tr);
          });
          content.appendChild(t);
        })
        .catch(showError);
    };
    form.appendChild(btn);
    content.appendChild(form);
  });
}

/* Query 7: bio age history */
function bioAgeHistory() {
  if (!ensureUser()) return;
  api
    .bioAgeHistory(selectedUserId)
    .then((d) => {
      content.innerHTML = `<h2>Bio Age History - User ${selectedUserId}</h2>`;
      const t = makeTable(["Date", "Model", "Bio Age", "Age Gap"]);
      d.history.forEach((h) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td>${h.computedAt.split("T")[0]}</td><td>${
          h.modelName
        }</td><td>${h.bioAgeYears.toFixed(1)}</td><td>${h.ageGap.toFixed(
          1
        )}</td>`;
        t.appendChild(tr);
      });
      content.appendChild(t);
    })
    .catch(showError);
}

/* Query 8: session details */
function sessionDetailsForm() {
  if (!ensureUser()) return;
  content.innerHTML = "";
  const form = document.createElement("div");
  form.className = "form-block";
  form.innerHTML = `<h4>Session Details - User ${selectedUserId}</h4>`;
  const results = document.createElement("div");
  api.listUsers().then((data) => {
    const sessionCount = data.users.find(
      (u) => u.userId == selectedUserId
    ).sessionCount;
    if (sessionCount === 0) {
      form.innerHTML += `<p>No sessions found.</p>`;
      results.appendChild(form);
      return;
    }
    form.innerHTML += `<label class="small">Select Session</label>`;
    const sel = document.createElement("select");
    sel.id = "sessSelect";
    for (let sid = 1; sid <= sessionCount; sid++) {
      const op = document.createElement("option");
      op.value = sid;
      op.textContent = `Session ${sid}`;
      sel.appendChild(op);
    }
    form.appendChild(sel);
    const btn = document.createElement("button");
    btn.textContent = "Run";
    btn.onclick = () => {
      const sid = parseInt(document.querySelector("#sessSelect").value);
      api
        .getSessionDetails(selectedUserId, sid)
        .then((d) => {
          results.innerHTML = `
              <h2>Session ${sid}</h2>
              <p><strong>Date:</strong> ${
                d.sessionDate
              } &nbsp; <strong>Fasting:</strong> ${
            d.fastingStatus ? "Yes" : "No"
          }</p>
            `;
          const t = makeTable(["Biomarker", "Value", "Units"]);
          d.measurements.forEach((m) => {
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td>${m.name}</td>
                <td>${m.value}</td>
                <td>${m.units}</td>
              `;
            t.appendChild(tr);
          });
          results.appendChild(t);
        })
        .catch(showError);
    };
    form.appendChild(btn);
    content.appendChild(form);
    content.appendChild(results);
  });
}

/* Query 9: biomarker catalog */
function biomarkerCatalog() {
  api
    .biomarkerCatalog()
    .then((d) => {
      content.innerHTML = "<h2>Biomarker Catalog</h2>";
      const t = makeTable(["ID", "Name", "Units", "Description"]);
      d.biomarkers.forEach((b) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${b.biomarkerId}</td>
          <td>${b.name}</td>
          <td>${b.units}</td>
          <td>${b.description}</td>
        `;
        t.appendChild(tr);
      });
      content.appendChild(t);
    })
    .catch(showError);
}

/* Query 10: biomarker ranges */
function biomarkerRangesForm() {
  content.innerHTML = "";
  const form = document.createElement("div");
  form.className = "form-block";
  form.innerHTML = "<h4>Reference Ranges</h4>";
  const results = document.createElement("div");
  api.biomarkerCatalog().then((cat) => {
    const sel = document.createElement("select");
    sel.id = "bioRangeSel";
    cat.biomarkers.forEach((b) => {
      const op = document.createElement("option");
      op.value = b.biomarkerId;
      op.textContent = `${b.biomarkerId} - ${b.name}`;
      sel.appendChild(op);
    });
    form.appendChild(sel);
    const btn = document.createElement("button");
    btn.textContent = "Run";
    btn.onclick = () => {
      api
        .biomarkerRanges(parseInt(sel.value))
        .then((d) => {
          const bio = cat.biomarkers.find((x) => x.biomarkerId == sel.value);
          results.innerHTML = `<h2>Reference Ranges - ${bio.name}</h2>`;
          const t = makeTable([
            "Type",
            "Sex",
            "Age Min",
            "Age Max",
            "Min",
            "Max",
          ]);
          d.ranges.forEach((r) => {
            const tr = document.createElement("tr");
            tr.innerHTML = `
              <td>${r.rangeType}</td>
              <td>${r.sex}</td>
              <td>${r.ageMin}</td>
              <td>${r.ageMax}</td>
              <td>${r.minVal}</td>
              <td>${r.maxVal}</td>
            `;
            t.appendChild(tr);
          });
          results.appendChild(t);
        })
        .catch(showError);
    };
    form.appendChild(btn);
    content.appendChild(form);
    content.appendChild(results);
  });
}

/* Query 11: users with session summary */
function usersSessionSummary() {
  api
    .usersSessionSummary()
    .then((data) => {
      content.innerHTML = "<h2>Users & Session Count</h2>";
      const t = makeTable(["User ID", "SEQN", "Sex", "Session Count"]);
      data.users.forEach((u) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${u.UserID}</td>
          <td>${u.SEQN}</td>
          <td>${u.Sex}</td>
          <td>${u.SessionCount}</td>
        `;
        t.appendChild(tr);
      });
      content.appendChild(t);
    })
    .catch(showError);
}

/* Query 12: biomarkers with measurement summary */
function biomarkersWithMeasurements() {
  api
    .biomarkersWithMeasurements()
    .then((data) => {
      content.innerHTML = "<h2>Biomarkers & Measurement Count</h2>";
      const t = makeTable(["Biomarker", "Units", "Measurement Count"]);
      data.biomarkers.forEach((b) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${b.Name}</td>
          <td>${b.Units}</td>
          <td>${b.MeasurementCount}</td>
        `;
        t.appendChild(tr);
      });
      content.appendChild(t);
    })
    .catch(showError);
}

/* Trend chart helper */
function drawTrend(canvas, data) {
  const ctx = canvas.getContext("2d");
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const pad = 40;
  const max = Math.max(...data.map((d) => d.value));
  const min = Math.min(...data.map((d) => d.value));
  const rng = max - min || 1;
  const step = (canvas.width - 2 * pad) / (data.length - 1);
  ctx.beginPath();
  ctx.strokeStyle = "#2980b9";
  data.forEach((d, i) => {
    const x = pad + i * step;
    const y =
      canvas.height - pad - ((d.value - min) / rng) * (canvas.height - 2 * pad);
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
    ctx.fillStyle = "#2980b9";
    ctx.beginPath();
    ctx.arc(x, y, 4, 0, Math.PI * 2);
    ctx.fill();
  });
  ctx.stroke();
  ctx.fillStyle = "#000";
  ctx.font = "12px Arial";
  ctx.fillText(max.toFixed(1), 5, pad);
  ctx.fillText(min.toFixed(1), 5, canvas.height - pad);
}

/* attach runBtn listener */
runButton.addEventListener("click", () => {
  const sel = document.querySelector('input[name="query"]:checked');
  if (!sel) {
    alert("Select a query");
    return;
  }
  switch (sel.value) {
    case "listUsers":
      listUsers();
      break;
    case "userProfile":
      userProfile();
      break;
    case "bioAge":
      bioAge();
      break;
    case "addMeasurements":
      addMeasurementsForm();
      break;
    case "compareRanges":
      compareRangesForm();
      break;
    case "trend":
      trendForm();
      break;
    case "bioAgeHistory":
      bioAgeHistory();
      break;
    case "sessionDetails":
      sessionDetailsForm();
      break;
    case "biomarkerCatalog":
      biomarkerCatalog();
      break;
    case "biomarkerRanges":
      biomarkerRangesForm();
      break;
    case "usersSessionSummary":
      usersSessionSummary();
      break;
    case "biomarkersWithMeasurements":
      biomarkersWithMeasurements();
      break;
  }
});
