/* helper functions */
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

// user biological age visuals
function createBioAgeVisualization(bioAgeData) {
  const container = document.createElement("div");
  container.className = "bioage-vis-area";
  const actualAge = bioAgeData.bioAgeYears - bioAgeData.ageGap;
  const ageGap = bioAgeData.ageGap;
  const maxVisualGap = 15;
  const infoText = document.createElement("div");
  infoText.className = "bioage-vis-info";
  infoText.innerHTML = `
        <span class="bioage-vis-value bioage-vis-bioage">Biological Age: ${bioAgeData.bioAgeYears.toFixed(
          1
        )}</span>
        <span class="bioage-vis-value bioage-vis-actualage">(Actual Age: ${actualAge.toFixed(
          1
        )})</span>
        <span class="bioage-vis-value bioage-vis-gap">Gap: ${
          ageGap > 0 ? "+" : ""
        }${ageGap.toFixed(1)} yrs</span>
    `;
  container.appendChild(infoText);
  const trackWrapper = document.createElement("div");
  trackWrapper.className = "bioage-vis-track-wrapper";
  const track = document.createElement("div");
  track.className = "bioage-vis-track";
  const zeroLine = document.createElement("div");
  zeroLine.className = "bioage-vis-line-zero";
  track.appendChild(zeroLine);
  const gapBar = document.createElement("div");
  gapBar.className = "bioage-vis-gap-bar";
  let barWidthPercent = (Math.abs(ageGap) / maxVisualGap) * 50;
  barWidthPercent = Math.min(barWidthPercent, 50);
  if (Math.abs(ageGap) >= 0.05) {
    barWidthPercent = Math.max(barWidthPercent, 0.5);
  }
  if (Math.abs(ageGap) < 0.05) {
    barWidthPercent = 1.5;
    gapBar.style.backgroundColor = "#B0BEC5";
    gapBar.style.left = `calc(50% - ${barWidthPercent / 2}%)`;
    gapBar.style.width = `${barWidthPercent}%`;
  } else {
    const COLOR_THRESHOLD_GAP = 0.5;
    let barColor;
    if (ageGap < 0) {
      barColor = ageGap < -COLOR_THRESHOLD_GAP ? "#4CAF50" : "#A5D6A7";
      gapBar.style.left = `${50 - barWidthPercent}%`;
    } else {
      barColor = ageGap > COLOR_THRESHOLD_GAP ? "#F44336" : "#EF9A9A";
      gapBar.style.left = "50%";
    }
    gapBar.style.backgroundColor = barColor;
    gapBar.style.width = `${barWidthPercent}%`;
  }
  track.appendChild(gapBar);
  trackWrapper.appendChild(track);
  const trackLabels = document.createElement("div");
  trackLabels.className = "bioage-vis-track-labels";
  const labelLeft = document.createElement("span");
  labelLeft.className = "bioage-vis-scale-label bioage-vis-scale-label-left";
  labelLeft.textContent = `-${maxVisualGap}y`;
  const labelCenter = document.createElement("span");
  labelCenter.className =
    "bioage-vis-scale-label bioage-vis-scale-label-center";
  labelCenter.textContent = "0y";
  const labelRight = document.createElement("span");
  labelRight.className = "bioage-vis-scale-label bioage-vis-scale-label-right";
  labelRight.textContent = `+${maxVisualGap}y`;
  trackLabels.appendChild(labelLeft);
  trackLabels.appendChild(labelCenter);
  trackLabels.appendChild(labelRight);
  trackWrapper.appendChild(trackLabels);
  container.appendChild(trackWrapper);
  return container;
}

// biomarkers vs reference ranges visuals
function createRangeBar(biomarkerName, userValueStr, rangeType, apiRangeData) {
  const userValue = parseFloat(userValueStr);
  let clinicalRangeData = null;
  let longevityRangeData = null;
  let unit = "";
  try {
    if (
      apiRangeData.clinicalRange &&
      (rangeType === "clinical" || rangeType === "both")
    ) {
      clinicalRangeData = JSON.parse(apiRangeData.clinicalRange);
      if (clinicalRangeData && clinicalRangeData.unit)
        unit = clinicalRangeData.unit;
    }
  } catch (e) {
    console.error(
      "Error parsing clinicalRange for " + biomarkerName + ":",
      apiRangeData.clinicalRange,
      e
    );
  }
  try {
    if (
      apiRangeData.longevityRange &&
      (rangeType === "longevity" || rangeType === "both")
    ) {
      longevityRangeData = JSON.parse(apiRangeData.longevityRange);
      if (longevityRangeData && longevityRangeData.unit && !unit)
        unit = longevityRangeData.unit;
    }
  } catch (e) {
    console.error(
      "Error parsing longevityRange for " + biomarkerName + ":",
      apiRangeData.longevityRange,
      e
    );
  }
  const mainContainer = document.createElement("div");
  mainContainer.className = "brb-main-container";
  if (rangeType === "clinical" && !clinicalRangeData) {
    mainContainer.textContent = "Clinical data not available.";
    return mainContainer;
  }
  if (rangeType === "longevity" && !longevityRangeData) {
    mainContainer.textContent = "Longevity data not available.";
    return mainContainer;
  }
  if (rangeType === "both" && (!clinicalRangeData || !longevityRangeData)) {
    mainContainer.textContent =
      "Clinical or Longevity data not available for 'Both' view.";
    return mainContainer;
  }
  const headerDiv = document.createElement("div");
  headerDiv.className = "brb-header";
  const titleSpan = document.createElement("span");
  titleSpan.className = "brb-title";
  titleSpan.textContent = biomarkerName;
  const rangeTextSpan = document.createElement("span");
  rangeTextSpan.className = "brb-range-text";
  headerDiv.appendChild(titleSpan);
  headerDiv.appendChild(rangeTextSpan);
  mainContainer.appendChild(headerDiv);
  const barArea = document.createElement("div");
  barArea.className = "brb-bar-area";
  const barElementContainer = document.createElement("div");
  barElementContainer.className = "brb-bar-container";
  let allRelevantPoints = [];
  if (!isNaN(userValue)) allRelevantPoints.push(userValue);
  let activeRanges = [];
  if (rangeType === "clinical" || rangeType === "both") {
    if (
      clinicalRangeData &&
      typeof clinicalRangeData.min === "number" &&
      typeof clinicalRangeData.max === "number"
    ) {
      allRelevantPoints.push(clinicalRangeData.min, clinicalRangeData.max);
      activeRanges.push(clinicalRangeData);
    }
  }
  if (rangeType === "longevity" || rangeType === "both") {
    if (
      longevityRangeData &&
      typeof longevityRangeData.min === "number" &&
      typeof longevityRangeData.max === "number"
    ) {
      allRelevantPoints.push(longevityRangeData.min, longevityRangeData.max);
      activeRanges.push(longevityRangeData);
    }
  }
  if (allRelevantPoints.length === 0) {
    mainContainer.textContent = "Not enough numeric data to draw bar.";
    return mainContainer;
  }
  let dataMin = Math.min(...allRelevantPoints);
  let dataMax = Math.max(...allRelevantPoints);
  if (dataMin === dataMax) {
    const absVal = Math.abs(dataMin) || 1;
    dataMin -= 0.5 * absVal;
    dataMax += 0.5 * absVal;
  }
  if (dataMin === dataMax) {
    dataMin -= 1;
    dataMax += 1;
  }
  const span = dataMax - dataMin;
  const padding =
    activeRanges.length > 0 ? span * 0.1 : Math.abs(dataMin) * 0.1 || 1;
  let displayMin = dataMin - padding;
  let displayMax = dataMax + padding;
  if (displayMin === displayMax) {
    displayMin = dataMin - (Math.abs(dataMin) * 0.5 || 1);
    displayMax = dataMax + (Math.abs(dataMax) * 0.5 || 1);
    if (displayMin === displayMax) {
      displayMin -= 1;
      displayMax += 1;
    }
  }
  const totalDisplaySpan = displayMax - displayMin;
  if (totalDisplaySpan <= 0) {
    mainContainer.textContent =
      "Cannot determine bar scale (zero or negative span).";
    return mainContainer;
  }
  const labelContainer = document.createElement("div");
  labelContainer.className = "brb-label-container";
  const createNumericLabel = (value, textPrefix = "") => {
    if (typeof value !== "number" || isNaN(value)) return;
    const posPercent = ((value - displayMin) / totalDisplaySpan) * 100;
    const label = document.createElement("span");
    label.className = "brb-label";
    label.textContent =
      textPrefix +
      value.toLocaleString(undefined, {
        minimumFractionDigits: 0,
        maximumFractionDigits: 1,
      });
    const clampedPos = Math.max(0, Math.min(100, posPercent));
    label.style.left = `${clampedPos}%`;
    if (clampedPos > 95) label.classList.add("brb-label--right-edge");
    else if (clampedPos < 5) label.classList.add("brb-label--left-edge");
    else label.classList.add("brb-label--center");
    labelContainer.appendChild(label);
  };
  const COLOR_OPTIMAL = "rgb(76, 175, 80)";
  const COLOR_NORMAL = "rgb(255, 235, 59)";
  const COLOR_OUT_OF_RANGE = "rgb(244, 67, 54)";
  const addBarSegment = (from, to, color) => {
    const start = Math.max(from, displayMin);
    const end = Math.min(to, displayMax);
    if (end > start) {
      const widthPercent = ((end - start) / totalDisplaySpan) * 100;
      const segment = document.createElement("div");
      segment.className = "brb-segment";
      segment.style.width = `${widthPercent}%`;
      segment.style.backgroundColor = color;
      barElementContainer.appendChild(segment);
    }
  };
  if (rangeType === "clinical" && clinicalRangeData) {
    rangeTextSpan.textContent =
      `Normal: ${clinicalRangeData.min} - ${clinicalRangeData.max} ${unit}`.trim();
    addBarSegment(displayMin, clinicalRangeData.min, COLOR_OUT_OF_RANGE);
    addBarSegment(clinicalRangeData.min, clinicalRangeData.max, COLOR_NORMAL);
    addBarSegment(clinicalRangeData.max, displayMax, COLOR_OUT_OF_RANGE);
    createNumericLabel(clinicalRangeData.min);
    createNumericLabel(clinicalRangeData.max);
  } else if (rangeType === "longevity" && longevityRangeData) {
    rangeTextSpan.textContent =
      `Optimal: ${longevityRangeData.min} - ${longevityRangeData.max} ${unit}`.trim();
    addBarSegment(displayMin, longevityRangeData.min, COLOR_NORMAL);
    addBarSegment(
      longevityRangeData.min,
      longevityRangeData.max,
      COLOR_OPTIMAL
    );
    addBarSegment(longevityRangeData.max, displayMax, COLOR_NORMAL);
    createNumericLabel(longevityRangeData.min);
    createNumericLabel(longevityRangeData.max);
  } else if (rangeType === "both" && clinicalRangeData && longevityRangeData) {
    rangeTextSpan.textContent =
      `Clinical: ${clinicalRangeData.min}-${clinicalRangeData.max}, Longevity: ${longevityRangeData.min}-${longevityRangeData.max} ${unit}`.trim();
    const points = [
      displayMin,
      clinicalRangeData.min,
      clinicalRangeData.max,
      longevityRangeData.min,
      longevityRangeData.max,
      displayMax,
    ]
      .filter(
        (v, i, a) => typeof v === "number" && !isNaN(v) && a.indexOf(v) === i
      )
      .sort((a, b) => a - b);
    for (let i = 0; i < points.length - 1; i++) {
      const p_start = points[i];
      const p_end = points[i + 1];
      if (p_start >= p_end) continue;
      const mid = (p_start + p_end) / 2;
      let segmentColor = COLOR_OUT_OF_RANGE;
      if (longevityRangeData.min <= mid && mid < longevityRangeData.max) {
        segmentColor = COLOR_OPTIMAL;
      } else if (clinicalRangeData.min <= mid && mid < clinicalRangeData.max) {
        segmentColor = COLOR_NORMAL;
      }
      addBarSegment(p_start, p_end, segmentColor);
    }
    createNumericLabel(clinicalRangeData.min);
    createNumericLabel(clinicalRangeData.max);
    createNumericLabel(longevityRangeData.min);
    createNumericLabel(longevityRangeData.max);
  } else {
    barElementContainer.textContent = "No range data to display bar.";
  }
  barArea.appendChild(barElementContainer);
  barArea.appendChild(labelContainer);
  mainContainer.appendChild(barArea);
  if (
    typeof userValue === "number" &&
    !isNaN(userValue) &&
    totalDisplaySpan > 0
  ) {
    const markerWrapper = document.createElement("div");
    markerWrapper.className = "brb-marker-wrapper";
    let markerPosPercent = ((userValue - displayMin) / totalDisplaySpan) * 100;
    markerPosPercent = Math.max(0, Math.min(100, markerPosPercent));
    markerWrapper.style.left = `${markerPosPercent}%`;
    const markerValueLabel = document.createElement("span");
    markerValueLabel.className = "brb-marker-value";
    markerValueLabel.textContent = userValue.toLocaleString(undefined, {
      minimumFractionDigits: 0,
      maximumFractionDigits: 1,
    });
    const markerTriangle = document.createElement("div");
    markerTriangle.className = "brb-marker-triangle";
    markerWrapper.appendChild(markerValueLabel);
    markerWrapper.appendChild(markerTriangle);
    barArea.appendChild(markerWrapper);
  }
  return mainContainer;
}

// biomarker trend visuals
function createBiomarkerTrendChart(trendData, biomarkerName, biomarkerId) {
  const chartContainer = document.createElement("div");
  chartContainer.className = "bmt-chart-container";
  const titleEl = document.createElement("h3");
  titleEl.className = "bmt-chart-title";
  titleEl.textContent = `Trend for ${biomarkerName} (ID: ${biomarkerId})`;
  chartContainer.appendChild(titleEl);
  const svgNs = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNs, "svg");
  const svgWidth = 650;
  const svgHeight = 320;
  const margin = { top: 20, right: 80, bottom: 60, left: 50 };
  const chartWidth = svgWidth - margin.left - margin.right;
  const chartHeight = svgHeight - margin.top - margin.bottom;
  svg.setAttribute("width", "100%");
  svg.setAttribute("height", svgHeight);
  svg.setAttribute("viewBox", `0 0 ${svgWidth} ${svgHeight}`);
  svg.classList.add("bmt-svg-chart");
  if (!trendData || trendData.length === 0) {
    const noDataMsg = document.createElement("p");
    noDataMsg.textContent = "No trend data to display in chart.";
    noDataMsg.style.textAlign = "center";
    chartContainer.appendChild(noDataMsg);
    return chartContainer;
  }
  const processedData = trendData
    .map((item) => ({
      date: new Date(item.date),
      value: parseFloat(item.value),
    }))
    .filter(
      (item) =>
        !isNaN(item.value) &&
        item.date instanceof Date &&
        !isNaN(item.date.getTime())
    )
    .sort((a, b) => a.date - b.date);
  if (processedData.length === 0) {
    const noDataMsg = document.createElement("p");
    noDataMsg.textContent = "No valid trend data points to plot.";
    noDataMsg.style.textAlign = "center";
    chartContainer.appendChild(noDataMsg);
    return chartContainer;
  }
  const allDates = processedData.map((d) => d.date);
  const allValues = processedData.map((d) => d.value);
  const minDate = new Date(Math.min.apply(null, allDates));
  const maxDate = new Date(Math.max.apply(null, allDates));
  let minValue = Math.min.apply(null, allValues);
  let maxValue = Math.max.apply(null, allValues);
  const yRange = maxValue - minValue;
  let yPadding = yRange * 0.1;
  if (yRange === 0) yPadding = Math.max(Math.abs(minValue) * 0.1, 0.5);
  if (yPadding === 0 && yRange !== 0) yPadding = 0.5;
  minValue -= yPadding;
  maxValue += yPadding;
  if (minValue === maxValue) {
    minValue -= 1;
    maxValue += 1;
  }
  const xScale = (date) => {
    const domainWidth = maxDate.getTime() - minDate.getTime();
    if (domainWidth === 0) return margin.left + chartWidth / 2;
    return (
      margin.left +
      ((date.getTime() - minDate.getTime()) / domainWidth) * chartWidth
    );
  };
  const yScale = (value) => {
    const domainHeight = maxValue - minValue;
    if (domainHeight === 0) return margin.top + chartHeight / 2;
    return (
      margin.top +
      chartHeight -
      ((value - minValue) / domainHeight) * chartHeight
    );
  };
  const axesGroup = document.createElementNS(svgNs, "g");
  axesGroup.classList.add("bmt-axes");
  const xAxisLine = document.createElementNS(svgNs, "line");
  xAxisLine.setAttribute("x1", margin.left);
  xAxisLine.setAttribute("y1", margin.top + chartHeight);
  xAxisLine.setAttribute("x2", margin.left + chartWidth);
  xAxisLine.setAttribute("y2", margin.top + chartHeight);
  axesGroup.appendChild(xAxisLine);
  const yAxisLine = document.createElementNS(svgNs, "line");
  yAxisLine.setAttribute("x1", margin.left);
  yAxisLine.setAttribute("y1", margin.top);
  yAxisLine.setAttribute("x2", margin.left);
  yAxisLine.setAttribute("y2", margin.top + chartHeight);
  axesGroup.appendChild(yAxisLine);
  const numXTicks = Math.min(5, Math.max(2, Math.floor(chartWidth / 100)));
  const timeDiff = maxDate.getTime() - minDate.getTime();
  for (let i = 0; i <= numXTicks; i++) {
    const ratio = numXTicks === 0 || timeDiff === 0 ? 0.5 : i / numXTicks;
    const tickDate =
      timeDiff === 0 ? minDate : new Date(minDate.getTime() + ratio * timeDiff);
    const x = xScale(tickDate);
    const xTick = document.createElementNS(svgNs, "line");
    xTick.setAttribute("x1", x);
    xTick.setAttribute("y1", margin.top + chartHeight);
    xTick.setAttribute("x2", x);
    xTick.setAttribute("y2", margin.top + chartHeight + 6);
    axesGroup.appendChild(xTick);
    const xLabel = document.createElementNS(svgNs, "text");
    xLabel.setAttribute("x", x);
    xLabel.setAttribute("y", margin.top + chartHeight + 22);
    let dateFormatOptions = { month: "short", day: "numeric" };
    if (timeDiff > 1000 * 60 * 60 * 24 * 300) {
      dateFormatOptions = { year: "2-digit", month: "short" };
    }
    if (timeDiff === 0) {
      dateFormatOptions = { year: "2-digit", month: "short", day: "numeric" };
    }
    xLabel.textContent = tickDate.toLocaleDateString(
      undefined,
      dateFormatOptions
    );
    xLabel.classList.add("bmt-axis-label", "bmt-x-axis-label");
    if (i === 0 && numXTicks > 0 && timeDiff > 0)
      xLabel.style.textAnchor = "start";
    else if (i === numXTicks && numXTicks > 0 && timeDiff > 0)
      xLabel.style.textAnchor = "end";
    axesGroup.appendChild(xLabel);
  }
  const numYTicks = 5;
  for (let i = 0; i <= numYTicks; i++) {
    const ratio = i / numYTicks;
    const tickValue = minValue + ratio * (maxValue - minValue);
    const y = yScale(tickValue);
    const yTick = document.createElementNS(svgNs, "line");
    yTick.setAttribute("x1", margin.left - 6);
    yTick.setAttribute("y1", y);
    yTick.setAttribute("x2", margin.left);
    yTick.setAttribute("y2", y);
    axesGroup.appendChild(yTick);
    const yLabel = document.createElementNS(svgNs, "text");
    yLabel.setAttribute("x", margin.left - 10);
    yLabel.setAttribute("y", y);
    yLabel.textContent = tickValue.toLocaleString(undefined, {
      minimumFractionDigits: 1,
      maximumFractionDigits: 2,
    });
    yLabel.classList.add("bmt-axis-label", "bmt-y-axis-label");
    axesGroup.appendChild(yLabel);
    const gridLine = document.createElementNS(svgNs, "line");
    gridLine.setAttribute("x1", margin.left);
    gridLine.setAttribute("y1", y);
    gridLine.setAttribute("x2", margin.left + chartWidth);
    gridLine.setAttribute("y2", y);
    gridLine.classList.add("bmt-grid-line");
    axesGroup.appendChild(gridLine);
  }
  svg.appendChild(axesGroup);
  const dataGroup = document.createElementNS(svgNs, "g");
  const lineLabelsGroup = document.createElementNS(svgNs, "g");
  const SERIES_COLOR = "#0d6efd";
  if (processedData.length > 1) {
    const pathData = processedData
      .map(
        (d, k) => `${k === 0 ? "M" : "L"} ${xScale(d.date)} ${yScale(d.value)}`
      )
      .join(" ");
    const path = document.createElementNS(svgNs, "path");
    path.setAttribute("d", pathData);
    path.setAttribute("stroke", SERIES_COLOR);
    path.classList.add("bmt-data-line");
    dataGroup.appendChild(path);
  }
  processedData.forEach((d) => {
    const circle = document.createElementNS(svgNs, "circle");
    circle.setAttribute("cx", xScale(d.date));
    circle.setAttribute("cy", yScale(d.value));
    circle.setAttribute("r", "3.5");
    circle.setAttribute("fill", SERIES_COLOR);
    circle.classList.add("bmt-data-point");
    const pointTitle = document.createElementNS(svgNs, "title");
    pointTitle.textContent = `${biomarkerName}: ${d.value.toLocaleString(
      undefined,
      { minimumFractionDigits: 1, maximumFractionDigits: 2 }
    )} on ${d.date.toLocaleDateString()}`;
    circle.appendChild(pointTitle);
    dataGroup.appendChild(circle);
  });
  if (processedData.length > 0) {
    const lastPoint = processedData[processedData.length - 1];
    const labelX = xScale(lastPoint.date) + 5;
    const labelY = yScale(lastPoint.value);
    const lineLabel = document.createElementNS(svgNs, "text");
    lineLabel.setAttribute("x", labelX);
    lineLabel.setAttribute("y", labelY);
    lineLabel.textContent = biomarkerName;
    lineLabel.setAttribute("fill", SERIES_COLOR);
    lineLabel.classList.add("bmt-line-label");
    lineLabelsGroup.appendChild(lineLabel);
  }
  svg.appendChild(dataGroup);
  svg.appendChild(lineLabelsGroup);
  chartContainer.appendChild(svg);
  return chartContainer;
}

// biological age history visuals
function createBioAgeHistoryChart(
  historyData,
  yKey = "bioAgeYears",
  chartBaseTitle = "Bio Age History"
) {
  const chartContainer = document.createElement("div");
  chartContainer.className = "bah-chart-container";
  const titleEl = document.createElement("h3");
  titleEl.className = "bah-chart-title";
  let yAxisTitle =
    yKey === "ageGap"
      ? "Age Gap"
      : yKey === "bioAgeYears"
      ? "Biological Age"
      : yKey;
  if (yKey === "bioAgeYears") yAxisTitle += " vs Actual Age";
  titleEl.textContent = `${chartBaseTitle} (${yAxisTitle})`;
  chartContainer.appendChild(titleEl);
  const svgNs = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNs, "svg");
  const svgWidth = 650;
  const svgHeight = 320;
  const margin = { top: 20, right: 100, bottom: 60, left: 50 };
  const chartWidth = svgWidth - margin.left - margin.right;
  const chartHeight = svgHeight - margin.top - margin.bottom;
  svg.setAttribute("width", "100%");
  svg.setAttribute("height", svgHeight);
  svg.setAttribute("viewBox", `0 0 ${svgWidth} ${svgHeight}`);
  svg.classList.add("bah-svg-chart");
  if (!historyData || historyData.length === 0) {
    const noDataMsg = document.createElement("p");
    noDataMsg.textContent = "No history data to display in chart.";
    noDataMsg.style.textAlign = "center";
    chartContainer.appendChild(noDataMsg);
    return chartContainer;
  }
  const dataByModel = {};
  let actualAgeDataSeries = [];
  const shouldPlotActualAge = yKey === "bioAgeYears";
  historyData.forEach((item) => {
    const value = parseFloat(item[yKey]);
    if (typeof value === "number" && !isNaN(value)) {
      if (!dataByModel[item.modelName]) {
        dataByModel[item.modelName] = [];
      }
      dataByModel[item.modelName].push({
        date: new Date(item.computedAt),
        value: value,
      });
      if (shouldPlotActualAge) {
        const actualAge =
          parseFloat(item.bioAgeYears) - parseFloat(item.ageGap);
        if (typeof actualAge === "number" && !isNaN(actualAge)) {
          actualAgeDataSeries.push({
            date: new Date(item.computedAt),
            value: actualAge,
          });
        }
      }
    }
  });
  let allDates = [];
  let allValues = [];
  let hasValidData = false;
  for (const model in dataByModel) {
    dataByModel[model].sort((a, b) => a.date - b.date);
    if (dataByModel[model].length > 0) {
      hasValidData = true;
      allDates.push(...dataByModel[model].map((d) => d.date));
      allValues.push(...dataByModel[model].map((d) => d.value));
    }
  }
  if (shouldPlotActualAge && actualAgeDataSeries.length > 0) {
    actualAgeDataSeries.sort((a, b) => a.date - b.date);
    actualAgeDataSeries = actualAgeDataSeries.filter(
      (item, index, self) =>
        index ===
        self.findIndex((t) => t.date.getTime() === item.date.getTime())
    );
    allDates.push(...actualAgeDataSeries.map((d) => d.date));
    allValues.push(...actualAgeDataSeries.map((d) => d.value));
    hasValidData = true;
  }
  if (!hasValidData) {
    const noDataMsg = document.createElement("p");
    noDataMsg.textContent = "No valid data points to plot.";
    noDataMsg.style.textAlign = "center";
    chartContainer.appendChild(noDataMsg);
    return chartContainer;
  }
  const uniqueDateTimestamps = [...new Set(allDates.map((d) => d.getTime()))];
  const minDate = new Date(
    Math.min.apply(
      null,
      uniqueDateTimestamps.length > 0 ? uniqueDateTimestamps : [Date.now()]
    )
  );
  const maxDate = new Date(
    Math.max.apply(
      null,
      uniqueDateTimestamps.length > 0 ? uniqueDateTimestamps : [Date.now()]
    )
  );
  let minValue = allValues.length > 0 ? Math.min.apply(null, allValues) : 0;
  let maxValue = allValues.length > 0 ? Math.max.apply(null, allValues) : 1;
  const yRange = maxValue - minValue;
  let yPadding = yRange * 0.1;
  if (yRange === 0) yPadding = Math.max(Math.abs(minValue) * 0.1, 0.5);
  if (yPadding === 0 && yRange !== 0) yPadding = 0.5;
  minValue -= yPadding;
  maxValue += yPadding;
  if (yKey === "ageGap") {
    const currentMin = minValue;
    const currentMax = maxValue;
    minValue = Math.min(currentMin, -0.5);
    maxValue = Math.max(currentMax, 0.5);
    if (currentMin > 0) minValue = Math.min(0, currentMin - yPadding);
    if (currentMax < 0) maxValue = Math.max(0, currentMax + yPadding);
  } else if (shouldPlotActualAge) {
    minValue = Math.min(minValue, 0);
  }
  if (minValue === maxValue) {
    minValue -= 1;
    maxValue += 1;
  }
  const xScale = (date) => {
    const domainWidth = maxDate.getTime() - minDate.getTime();
    if (domainWidth === 0) return margin.left + chartWidth / 2;
    return (
      margin.left +
      ((date.getTime() - minDate.getTime()) / domainWidth) * chartWidth
    );
  };
  const yScale = (value) => {
    const domainHeight = maxValue - minValue;
    if (domainHeight === 0) return margin.top + chartHeight / 2;
    return (
      margin.top +
      chartHeight -
      ((value - minValue) / domainHeight) * chartHeight
    );
  };
  const axesGroup = document.createElementNS(svgNs, "g");
  axesGroup.classList.add("bah-axes");
  const xAxisLine = document.createElementNS(svgNs, "line");
  xAxisLine.setAttribute("x1", margin.left);
  xAxisLine.setAttribute("y1", margin.top + chartHeight);
  xAxisLine.setAttribute("x2", margin.left + chartWidth);
  xAxisLine.setAttribute("y2", margin.top + chartHeight);
  axesGroup.appendChild(xAxisLine);
  const yAxisLine = document.createElementNS(svgNs, "line");
  yAxisLine.setAttribute("x1", margin.left);
  yAxisLine.setAttribute("y1", margin.top);
  yAxisLine.setAttribute("x2", margin.left);
  yAxisLine.setAttribute("y2", margin.top + chartHeight);
  axesGroup.appendChild(yAxisLine);
  const numXTicks = Math.min(5, Math.max(2, Math.floor(chartWidth / 100)));
  const timeDiff = maxDate.getTime() - minDate.getTime();
  for (let i = 0; i <= numXTicks; i++) {
    const ratio = numXTicks === 0 || timeDiff === 0 ? 0.5 : i / numXTicks;
    const tickDate =
      timeDiff === 0 ? minDate : new Date(minDate.getTime() + ratio * timeDiff);
    const x = xScale(tickDate);
    const xTick = document.createElementNS(svgNs, "line");
    xTick.setAttribute("x1", x);
    xTick.setAttribute("y1", margin.top + chartHeight);
    xTick.setAttribute("x2", x);
    xTick.setAttribute("y2", margin.top + chartHeight + 6);
    axesGroup.appendChild(xTick);
    const xLabel = document.createElementNS(svgNs, "text");
    xLabel.setAttribute("x", x);
    xLabel.setAttribute("y", margin.top + chartHeight + 22);
    let dateFormatOptions = { month: "short", day: "numeric" };
    if (timeDiff > 1000 * 60 * 60 * 24 * 300) {
      dateFormatOptions = { year: "2-digit", month: "short" };
    }
    if (timeDiff === 0) {
      dateFormatOptions = { year: "2-digit", month: "short", day: "numeric" };
    }
    xLabel.textContent = tickDate.toLocaleDateString(
      undefined,
      dateFormatOptions
    );
    xLabel.classList.add("bah-axis-label", "bah-x-axis-label");
    if (i === 0 && numXTicks > 0 && timeDiff > 0)
      xLabel.style.textAnchor = "start";
    else if (i === numXTicks && numXTicks > 0 && timeDiff > 0)
      xLabel.style.textAnchor = "end";
    axesGroup.appendChild(xLabel);
  }
  const numYTicks = 5;
  let zeroLabelHandledByTickLoop = false;
  for (let i = 0; i <= numYTicks; i++) {
    const ratio = i / numYTicks;
    const tickValue = minValue + ratio * (maxValue - minValue);
    const y = yScale(tickValue);
    const yTick = document.createElementNS(svgNs, "line");
    yTick.setAttribute("x1", margin.left - 6);
    yTick.setAttribute("y1", y);
    yTick.setAttribute("x2", margin.left);
    yTick.setAttribute("y2", y);
    axesGroup.appendChild(yTick);
    const yLabel = document.createElementNS(svgNs, "text");
    yLabel.setAttribute("y", y);
    yLabel.textContent = tickValue.toLocaleString(undefined, {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    });
    yLabel.classList.add("bah-axis-label", "bah-y-axis-label");
    if (yKey === "ageGap" && Math.abs(tickValue - 0) < 0.01) {
      yLabel.classList.add("bah-zero-label-prominent");
      yLabel.setAttribute("x", margin.left + chartWidth + 10);
      yLabel.style.textAnchor = "start";
      zeroLabelHandledByTickLoop = true;
    } else {
      yLabel.setAttribute("x", margin.left - 10);
      yLabel.style.textAnchor = "end";
    }
    axesGroup.appendChild(yLabel);
    const gridLine = document.createElementNS(svgNs, "line");
    gridLine.setAttribute("x1", margin.left);
    gridLine.setAttribute("y1", y);
    gridLine.setAttribute("x2", margin.left + chartWidth);
    gridLine.setAttribute("y2", y);
    gridLine.classList.add("bah-grid-line");
    axesGroup.appendChild(gridLine);
  }
  if (
    yKey === "ageGap" &&
    minValue <= 0 &&
    maxValue >= 0 &&
    minValue !== maxValue
  ) {
    const yZero = yScale(0);
    if (yZero >= margin.top && yZero <= margin.top + chartHeight) {
      const existingGridLines = axesGroup.querySelectorAll(".bah-grid-line");
      existingGridLines.forEach((line) => {
        if (Math.abs(parseFloat(line.getAttribute("y1")) - yZero) < 0.1) {
          line.remove();
        }
      });
      const zeroLineProminent = document.createElementNS(svgNs, "line");
      zeroLineProminent.setAttribute("x1", margin.left);
      zeroLineProminent.setAttribute("y1", yZero);
      zeroLineProminent.setAttribute("x2", margin.left + chartWidth);
      zeroLineProminent.setAttribute("y2", yZero);
      zeroLineProminent.classList.add(
        "bah-grid-line",
        "bah-zero-line-prominent"
      );
      axesGroup.appendChild(zeroLineProminent);
      if (!zeroLabelHandledByTickLoop) {
        const yLabelZero = document.createElementNS(svgNs, "text");
        yLabelZero.setAttribute("x", margin.left + chartWidth + 10);
        yLabelZero.setAttribute("y", yZero);
        yLabelZero.textContent = "0.0";
        yLabelZero.classList.add(
          "bah-axis-label",
          "bah-y-axis-label",
          "bah-zero-label-prominent"
        );
        yLabelZero.style.textAnchor = "start";
        axesGroup.appendChild(yLabelZero);
      }
    }
  }
  svg.appendChild(axesGroup);
  const dataGroup = document.createElementNS(svgNs, "g");
  const lineLabelsGroup = document.createElementNS(svgNs, "g");
  const MODEL_COLORS = [
    "#0d6efd",
    "#198754",
    "#ffc107",
    "#6f42c1",
    "#fd7e14",
    "#20c997",
  ];
  const ACTUAL_AGE_COLOR = "#dc3545";
  let colorIndex = 0;
  const legendItems = [];
  const drawSeries = (
    seriesData,
    seriesName,
    seriesColor,
    isActualAge = false
  ) => {
    if (seriesData.length === 0) return;
    legendItems.push({ name: seriesName, color: seriesColor });
    if (seriesData.length > 1) {
      const pathData = seriesData
        .map(
          (d, k) =>
            `${k === 0 ? "M" : "L"} ${xScale(d.date)} ${yScale(d.value)}`
        )
        .join(" ");
      const path = document.createElementNS(svgNs, "path");
      path.setAttribute("d", pathData);
      path.setAttribute("stroke", seriesColor);
      path.classList.add("bah-data-line");
      if (isActualAge) path.style.strokeDasharray = "4,4";
      dataGroup.appendChild(path);
    }
    seriesData.forEach((d) => {
      const circle = document.createElementNS(svgNs, "circle");
      circle.setAttribute("cx", xScale(d.date));
      circle.setAttribute("cy", yScale(d.value));
      circle.setAttribute("r", isActualAge ? "2.5" : "3.5");
      circle.setAttribute("fill", seriesColor);
      circle.classList.add("bah-data-point");
      const pointTitle = document.createElementNS(svgNs, "title");
      pointTitle.textContent = `${seriesName}: ${d.value.toLocaleString(
        undefined,
        { minimumFractionDigits: 1, maximumFractionDigits: 1 }
      )} on ${d.date.toLocaleDateString()}`;
      circle.appendChild(pointTitle);
      dataGroup.appendChild(circle);
    });
    if (seriesData.length > 0) {
      const lastPoint = seriesData[seriesData.length - 1];
      let labelX = xScale(lastPoint.date) + 5;
      const labelY = yScale(lastPoint.value);
      const lineLabel = document.createElementNS(svgNs, "text");
      lineLabel.textContent = seriesName;
      lineLabel.setAttribute("y", labelY);
      lineLabel.setAttribute("fill", seriesColor);
      lineLabel.classList.add("bah-line-label");
      const tempMeasure = document.createElementNS(svgNs, "text");
      tempMeasure.textContent = seriesName;
      tempMeasure.classList.add("bah-line-label");
      svg.appendChild(tempMeasure);
      const labelWidth = tempMeasure.getComputedTextLength
        ? tempMeasure.getComputedTextLength()
        : seriesName.length * 6;
      svg.removeChild(tempMeasure);
      if (labelX + labelWidth > svgWidth - 5) {
        labelX = xScale(lastPoint.date) - 5 - labelWidth;
        lineLabel.style.textAnchor = "end";
      } else {
        lineLabel.style.textAnchor = "start";
      }
      lineLabel.setAttribute("x", labelX);
      lineLabelsGroup.appendChild(lineLabel);
    }
  };
  for (const modelName in dataByModel) {
    drawSeries(
      dataByModel[modelName],
      modelName,
      MODEL_COLORS[colorIndex % MODEL_COLORS.length]
    );
    colorIndex++;
  }
  if (shouldPlotActualAge && actualAgeDataSeries.length > 0) {
    drawSeries(actualAgeDataSeries, "Actual Age", ACTUAL_AGE_COLOR, true);
  }
  svg.appendChild(dataGroup);
  svg.appendChild(lineLabelsGroup);
  chartContainer.appendChild(svg);
  if (legendItems.length > 0) {
    const legend = document.createElement("div");
    legend.className = "bah-legend";
    legendItems.forEach((item) => {
      const legendItem = document.createElement("div");
      legendItem.className = "bah-legend-item";
      legendItem.innerHTML = `<span class="bah-legend-swatch" style="background-color:${
        item.color
      }; ${
        item.name === "Actual Age"
          ? "border: 1px solid " +
            item.color +
            "; background-image: repeating-linear-gradient(-45deg, transparent, transparent 2px, " +
            item.color +
            " 2px, " +
            item.color +
            " 4px);"
          : ""
      }"></span> ${item.name}`;
      legend.appendChild(legendItem);
    });
    chartContainer.appendChild(legend);
  }
  return chartContainer;
}

// biomarker reference ranges visuals
function createSingleRangeBar(rangeData, scaleMin, scaleMax) {
  const container = document.createElement("div");
  container.className = "srb-area";
  const minVal = rangeData.minVal;
  const maxVal = rangeData.maxVal;
  if (
    typeof minVal !== "number" ||
    typeof maxVal !== "number" ||
    isNaN(minVal) ||
    isNaN(maxVal) ||
    minVal > maxVal
  ) {
    container.textContent =
      typeof minVal === "number" && typeof maxVal === "number"
        ? `${minVal.toLocaleString()} - ${maxVal.toLocaleString()}`
        : "N/A";
    return container;
  }
  const totalScaleSpan = scaleMax - scaleMin;
  if (totalScaleSpan <= 0) {
    container.textContent = `${minVal.toLocaleString()} - ${maxVal.toLocaleString()}`;
    return container;
  }
  const track = document.createElement("div");
  track.className = "srb-track";
  let barOffsetPercent = ((minVal - scaleMin) / totalScaleSpan) * 100;
  let barWidthPercent = ((maxVal - minVal) / totalScaleSpan) * 100;
  barOffsetPercent = Math.max(0, barOffsetPercent);
  barWidthPercent = Math.max(0.5, barWidthPercent);
  if (barOffsetPercent + barWidthPercent > 100) {
    barWidthPercent = 100 - barOffsetPercent;
  }
  barWidthPercent = Math.max(0, barWidthPercent);
  if (barWidthPercent > 0) {
    const bar = document.createElement("div");
    bar.className = "srb-bar";
    bar.style.left = `${barOffsetPercent}%`;
    bar.style.width = `${barWidthPercent}%`;
    track.appendChild(bar);
  }
  container.appendChild(track);
  const labelContainer = document.createElement("div");
  labelContainer.className = "srb-label-container";
  const createLabel = (value, positionPercentOnScale) => {
    const label = document.createElement("span");
    label.className = "srb-value-label";
    label.textContent = value.toLocaleString(undefined, {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    });
    const clampedPos = Math.max(0, Math.min(100, positionPercentOnScale));
    label.style.left = `${clampedPos}%`;
    if (clampedPos > 95) {
      label.style.transform = "translateX(-100%)";
    } else if (clampedPos < 5) {
      label.style.transform = "translateX(0%)";
    } else {
      label.style.transform = "translateX(-50%)";
    }
    labelContainer.appendChild(label);
  };
  const minLabelPosPercent = ((minVal - scaleMin) / totalScaleSpan) * 100;
  const maxLabelPosPercent = ((maxVal - scaleMin) / totalScaleSpan) * 100;
  createLabel(minVal, minLabelPosPercent);
  const positionDifference = Math.abs(maxLabelPosPercent - minLabelPosPercent);
  if (maxVal !== minVal && positionDifference > 8) {
    createLabel(maxVal, maxLabelPosPercent);
  } else if (maxVal === minVal && positionDifference <= 8) {
  }
  if (barWidthPercent > 0 || minVal === maxVal) {
    container.appendChild(labelContainer);
  }
  return container;
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
      if (res.status === 404) {
        return { bioAges: [] }; // No bio-age data found
      }
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
  trend: async (userId, biomarkerId, limit = 20, range = "") => {
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

  // 11. Users age distribution
  ageDistribution: async () => {
    const res = await fetch(`${API_BASE}/users/age-distribution`);
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
          <td>${b.takenAt.slice(0, 10)}</td>
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
      const t = makeTable([
        "Model",
        "Bio Age",
        "Age Gap",
        "Visualization",
        "Computed At",
      ]);
      d.bioAges.forEach((b) => {
        const tr = document.createElement("tr");
        const modelNameCell = document.createElement("td");
        modelNameCell.textContent = b.modelName;
        tr.appendChild(modelNameCell);
        const bioAgeCell = document.createElement("td");
        bioAgeCell.textContent = b.bioAgeYears.toFixed(1);
        tr.appendChild(bioAgeCell);
        const ageGapCell = document.createElement("td");
        const ageGapValue = b.ageGap;
        ageGapCell.textContent = `${
          ageGapValue > 0 ? "+" : ""
        }${ageGapValue.toFixed(1)}`;
        const SIGNIFICANT_GAP_THRESHOLD_TEXT = 0.5;
        if (ageGapValue > SIGNIFICANT_GAP_THRESHOLD_TEXT) {
          ageGapCell.style.color = "#C62828";
        } else if (ageGapValue < -SIGNIFICANT_GAP_THRESHOLD_TEXT) {
          ageGapCell.style.color = "#2E7D32";
        }
        tr.appendChild(ageGapCell);
        const vizCell = document.createElement("td");
        vizCell.appendChild(createBioAgeVisualization(b));
        tr.appendChild(vizCell);
        const computedAtCell = document.createElement("td");
        computedAtCell.textContent = b.computedAt.split("T")[0];
        tr.appendChild(computedAtCell);
        t.appendChild(tr);
      });
      content.appendChild(t);
      content.appendChild(document.createElement("br"));
      for (const modelName of ["Phenotypic Age", "Homeostatic Dysregulation"]) {
        const btn = document.createElement("button");
        btn.textContent = "Recalculate " + modelName;
        btn.onclick = () => {
          api
            .calculateBioAge(selectedUserId, modelName)
            .then(() => {
              bioAge();
            })
            .catch(showError);
        };
        content.appendChild(btn);
        content.appendChild(document.createTextNode(" "));
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
    const rangeType = document.querySelector("#rangeType").value;
    api
      .compareRanges(selectedUserId, rangeType)
      .then((d) => {
        results.innerHTML = `<h2>Range Comparison - ${rangeType}</h2>`;
        const t = makeTable(["Biomarker", "Value", "Status", "Visualization"]);
        d.ranges.forEach((r) => {
          const tr = document.createElement("tr");
          tr.innerHTML = `<td>${r.name}</td><td>${
            r.value
          }</td><td class="status-${r.status.toLowerCase()}">${
            r.status == "OutOfRange" ? "Out of Range" : r.status
          }</td>`;
          const vizCell = document.createElement("td");
          const rangeBarElement = createRangeBar(r.name, r.value, rangeType, r);
          vizCell.appendChild(rangeBarElement);
          tr.appendChild(vizCell);
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

/* Query 6: biomarker trend */
function trendForm() {
  if (!ensureUser()) return;
  content.innerHTML = "";
  const form = document.createElement("div");
  form.className = "form-block";
  form.innerHTML = `<h4>Biomarker Trend - User ${selectedUserId}</h4>`;
  const results = document.createElement("div");
  api.biomarkerCatalog().then((cat) => {
    const sel = document.createElement("select");
    sel.id = "bioSel";
    cat.biomarkers.forEach((b) => {
      const op = document.createElement("option");
      op.value = b.biomarkerId;
      op.textContent = `${b.biomarkerId} - ${b.name}`;
      op.dataset.biomarkerName = b.name;
      sel.appendChild(op);
    });
    form.appendChild(sel);

    const label = document.createElement("label");
    label.className = "small";
    label.textContent = "Number of points";
    const input = document.createElement("input");
    input.type = "number";
    input.id = "trendLimit";
    input.value = "10";
    input.min = "3";
    input.max = "50";
    form.appendChild(label);
    form.appendChild(input);

    const rangeLabel = document.createElement("label");
    rangeLabel.className = "small";
    rangeLabel.textContent = "Range ";
    const rangeInput = document.createElement("input");
    rangeInput.type = "number";
    rangeInput.id = "trendRangeNum";
    rangeInput.value = "10";
    rangeInput.min = "1";
    rangeInput.style.width = "60px";
    const rangeUnit = document.createElement("select");
    rangeUnit.id = "trendRangeUnit";
    ["days", "months", "years"].forEach((unit) => {
      const opt = document.createElement("option");
      opt.value = unit;
      opt.textContent = unit;
      rangeUnit.appendChild(opt);
    });
    rangeUnit.style.width = "100px";
    rangeUnit.value = "years";
    form.appendChild(rangeLabel);
    form.appendChild(document.createElement("br"));
    form.appendChild(rangeInput);
    form.appendChild(document.createTextNode(" "));
    form.appendChild(rangeUnit);
    form.appendChild(document.createElement("br"));

    const btn = document.createElement("button");
    btn.textContent = "Run";
    btn.onclick = () => {
      results.innerHTML = "";
      const selectedOption = sel.options[sel.selectedIndex];
      const biomarkerId = parseInt(sel.value);
      const biomarkerName = selectedOption.dataset.biomarkerName || sel.value;
      const rangeStr =
        document.querySelector("#trendRangeNum").value +
        document.querySelector("#trendRangeUnit").value;
      api
        .trend(
          selectedUserId,
          biomarkerId,
          parseInt(document.querySelector("#trendLimit").value),
          rangeStr
        )
        .then((d) => {
          const sectionTitle = document.createElement("h2");
          sectionTitle.textContent = `Trend Results for ${biomarkerName}`;
          results.appendChild(sectionTitle);
          if (d.trend && d.trend.length > 0) {
            const chartElement = createBiomarkerTrendChart(
              d.trend,
              biomarkerName,
              biomarkerId.toString()
            );
            results.appendChild(chartElement);
          } else {
            const noChartDataMsg = document.createElement("p");
            noChartDataMsg.textContent =
              "No data available to display chart for this biomarker.";
            results.appendChild(noChartDataMsg);
          }
          if (d.trend && d.trend.length > 0) {
            const t = makeTable(["Date", "Value"]);
            const tableData = [...d.trend].reverse();
            tableData.forEach((r) => {
              const tr = document.createElement("tr");
              const dateCell = document.createElement("td");
              dateCell.textContent = r.date;
              tr.appendChild(dateCell);
              const valueCell = document.createElement("td");
              valueCell.textContent = r.value;
              tr.appendChild(valueCell);
              t.appendChild(tr);
            });
            results.appendChild(t);
          } else {
            const noTableDataMsg = document.createElement("p");
            noTableDataMsg.textContent =
              "No data available to display in table.";
            results.appendChild(noTableDataMsg);
          }
        })
        .catch(showError);
    };
    form.appendChild(btn);
    content.appendChild(form);
    content.appendChild(results);
  });
}

/* Query 7: bio age history */
function bioAgeHistory() {
  if (!ensureUser()) return;
  api
    .bioAgeHistory(selectedUserId)
    .then((d) => {
      content.innerHTML = `<h2>Bio Age History - User ${selectedUserId}</h2>`;
      if (d.history && d.history.length > 0) {
        const t = makeTable([
          "Date",
          "Model",
          "Actual Age",
          "Bio Age",
          "Age Gap",
        ]);
        d.history.forEach((h) => {
          const tr = document.createElement("tr");
          const bioAgeNum = parseFloat(h.bioAgeYears);
          const ageGapNum = parseFloat(h.ageGap);
          const actualAgeNum = bioAgeNum - ageGapNum;
          const dateCell = document.createElement("td");
          dateCell.textContent = h.computedAt.split("T")[0];
          tr.appendChild(dateCell);
          const modelCell = document.createElement("td");
          modelCell.textContent = h.modelName;
          tr.appendChild(modelCell);
          const actualAgeCell = document.createElement("td");
          actualAgeCell.textContent =
            typeof actualAgeNum === "number" && !isNaN(actualAgeNum)
              ? actualAgeNum.toFixed(1)
              : "N/A";
          tr.appendChild(actualAgeCell);
          const bioAgeCell = document.createElement("td");
          bioAgeCell.textContent = bioAgeNum.toFixed(1);
          tr.appendChild(bioAgeCell);
          const ageGapCell = document.createElement("td");
          ageGapCell.textContent = `${
            ageGapNum > 0 ? "+" : ""
          }${ageGapNum.toFixed(1)}`;
          if (ageGapNum > 0.5) {
            ageGapCell.style.color = "#C62828";
          } else if (ageGapNum < -0.5) {
            ageGapCell.style.color = "#2E7D32";
          }
          tr.appendChild(ageGapCell);
          t.appendChild(tr);
        });
        content.appendChild(t);
      } else {
        const noTableDataMsg = document.createElement("p");
        noTableDataMsg.textContent = "No historical data available.";
        content.appendChild(noTableDataMsg);
      }
      if (d.history && d.history.length > 0) {
        const chartBioAgeVsActualElement = createBioAgeHistoryChart(
          d.history,
          "bioAgeYears",
          "Age Trends"
        );
        content.appendChild(chartBioAgeVsActualElement);
        const chartAgeGapElement = createBioAgeHistoryChart(
          d.history,
          "ageGap",
          "Age Gap History"
        );
        content.appendChild(chartAgeGapElement);
      }
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
    const user = data.users.find((u) => u.userId == selectedUserId);
    if (!user || user.sessionCount === 0) {
      form.innerHTML += `<p>No sessions found for user ${selectedUserId}.</p>`;
      content.appendChild(form); // Ensure form is added even if no sessions
      return;
    }
    form.innerHTML += `<label class="small">Select Session</label>`;
    const sel = document.createElement("select");
    sel.id = "sessSelect";
    for (let sid = 1; sid <= user.sessionCount; sid++) {
      const op = document.createElement("option");
      op.value = sid;
      op.textContent = `Session ${sid}`;
      sel.appendChild(op);
    }
    form.appendChild(sel);
    const btn = document.createElement("button");
    btn.textContent = "Run";
    btn.onclick = () => {
      results.innerHTML = ""; // Clear previous results
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
      results.innerHTML = ""; // Clear previous results
      api
        .biomarkerRanges(parseInt(sel.value))
        .then((d) => {
          const bio = cat.biomarkers.find((x) => x.biomarkerId == sel.value);
          results.innerHTML = `<h2>Reference Ranges - ${bio.name}</h2>`;
          let overallDisplayMin = 0;
          let overallDisplayMax = 100;
          let canDrawBars = false;
          if (d.ranges && d.ranges.length > 0) {
            const numericRanges = d.ranges.filter(
              (r) =>
                typeof r.minVal === "number" &&
                typeof r.maxVal === "number" &&
                !isNaN(r.minVal) &&
                !isNaN(r.maxVal) &&
                r.minVal <= r.maxVal
            );
            if (numericRanges.length > 0) {
              let dataMin = Math.min(...numericRanges.map((r) => r.minVal));
              let dataMax = Math.max(...numericRanges.map((r) => r.maxVal));
              const span = dataMax - dataMin;
              let padding;
              if (span === 0) {
                padding = Math.max(Math.abs(dataMin) * 0.1, 0.5);
              } else {
                padding = span * 0.1;
              }
              if (padding === 0) padding = 0.5;
              overallDisplayMin = dataMin - padding;
              overallDisplayMax = dataMax + padding;
              if (overallDisplayMin >= overallDisplayMax) {
                overallDisplayMin = dataMin - (Math.abs(dataMin * 0.5) || 0.5);
                overallDisplayMax = dataMax + (Math.abs(dataMax * 0.5) || 0.5);
                if (overallDisplayMin >= overallDisplayMax) {
                  overallDisplayMin = dataMin - 1;
                  overallDisplayMax = dataMax + 1;
                }
              }
              canDrawBars = true;
            }
          }
          const t = makeTable([
            "Type",
            "Sex",
            "Age Min",
            "Age Max",
            "Min",
            "Max",
            "Visualization",
          ]);
          d.ranges.forEach((r) => {
            const tr = document.createElement("tr");
            const typeCell = document.createElement("td");
            typeCell.textContent = r.rangeType;
            tr.appendChild(typeCell);
            const sexCell = document.createElement("td");
            sexCell.textContent = r.sex;
            tr.appendChild(sexCell);
            const ageMinCell = document.createElement("td");
            ageMinCell.textContent = r.ageMin;
            tr.appendChild(ageMinCell);
            const ageMaxCell = document.createElement("td");
            ageMaxCell.textContent = r.ageMax;
            tr.appendChild(ageMaxCell);
            const minValCell = document.createElement("td");
            minValCell.textContent =
              typeof r.minVal === "number"
                ? r.minVal.toLocaleString()
                : r.minVal;
            tr.appendChild(minValCell);
            const maxValCell = document.createElement("td");
            maxValCell.textContent =
              typeof r.maxVal === "number"
                ? r.maxVal.toLocaleString()
                : r.maxVal;
            tr.appendChild(maxValCell);
            const vizCell = document.createElement("td");
            if (
              canDrawBars &&
              typeof r.minVal === "number" &&
              typeof r.maxVal === "number"
            ) {
              vizCell.appendChild(
                createSingleRangeBar(r, overallDisplayMin, overallDisplayMax)
              );
            } else {
              vizCell.textContent =
                typeof r.minVal === "number" && typeof r.maxVal === "number"
                  ? `${r.minVal}-${r.maxVal}`
                  : "N/A";
            }
            tr.appendChild(vizCell);
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

/* Query 11: age distribution */
function ageDistribution() {
  api
    .ageDistribution()
    .then((data) => {
      content.innerHTML = "<h2>User Count by Age Group & Sex</h2>";
      const t = makeTable(["Age Group", "Sex", "User Count"]);
      if (data.ageDistribution && data.ageDistribution.length > 0) {
        data.ageDistribution.forEach((row) => {
          const tr = document.createElement("tr");
          tr.innerHTML = `
            <td>${row.AgeGroup}</td>
            <td>${row.Sex}</td>
            <td>${row.UserCount}</td>
          `;
          t.appendChild(tr);
        });
        content.appendChild(t);
      } else {
        content.innerHTML += "<p>No data available.</p>";
      }
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
    case "ageDistribution":
      ageDistribution();
      break;
    case "biomarkersWithMeasurements":
      biomarkersWithMeasurements();
      break;
  }
});
