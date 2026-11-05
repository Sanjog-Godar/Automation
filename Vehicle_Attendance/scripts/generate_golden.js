// Ensure UTC timezone so Date operations are deterministic across all environments
process.env.TZ = 'UTC';

const fs = require('fs');
const path = require('path');
const mod = require('nepali-date-converter');
const NepaliDate = mod.default || mod;

const years = [2080, 2081, 2082, 2083, 2084];
const result = [];
const yearMonthTable = {};

years.forEach(year => {
  yearMonthTable[year] = [];
  for (let monthIndex = 0; monthIndex < 12; monthIndex++) {
    // Determine days in month by testing day counts 32 down to 29
    let daysInMonth = null;
    for (let d = 32; d >= 29; d--) {
      try {
        const testDate = new NepaliDate(year, monthIndex, d);
        if (testDate.getMonth() === monthIndex) {
          daysInMonth = d;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!daysInMonth) {
      throw new Error(`Failed to determine valid day count for BS year ${year}, monthIndex ${monthIndex}`);
    }

    yearMonthTable[year].push(daysInMonth);

    const firstDayNepali = new NepaliDate(year, monthIndex, 1);
    const lastDayNepali = new NepaliDate(year, monthIndex, daysInMonth);

    const firstAD = firstDayNepali.toJsDate();
    const lastAD = lastDayNepali.toJsDate();

    const formatADUtc = (d) => {
      const y = d.getUTCFullYear();
      const m = String(d.getUTCMonth() + 1).padStart(2, '0');
      const day = String(d.getUTCDate()).padStart(2, '0');
      return `${y}-${m}-${day}`;
    };

    result.push({
      year,
      month: monthIndex + 1, // 1-12
      monthIndex, // 0-11
      daysInMonth,
      startDateAD: formatADUtc(firstAD),
      endDateAD: formatADUtc(lastAD),
      startDayOfWeek: firstAD.getUTCDay(), // 0=Sunday, 6=Saturday
    });
  }
});

if (result.length !== 60) {
  throw new Error(`Expected exactly 60 months, but generated ${result.length}`);
}

// 1. Emit test/fixtures/nepali_golden.json
const jsonOutputPath = path.resolve(__dirname, '..', 'Flutter App', 'vehicle_app', 'test', 'fixtures', 'nepali_golden.json');
fs.mkdirSync(path.dirname(jsonOutputPath), { recursive: true });
fs.writeFileSync(jsonOutputPath, JSON.stringify(result, null, 2), 'utf-8');

// 2. Emit lib/core/utils/nepali_month_table.g.dart
const dartOutputPath = path.resolve(__dirname, '..', 'Flutter App', 'vehicle_app', 'lib', 'core', 'utils', 'nepali_month_table.g.dart');
fs.mkdirSync(path.dirname(dartOutputPath), { recursive: true });

let dartCode = `// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from scripts/generate_golden.js using nepali-date-converter.

/// Month metadata for precomputed BS months.
class NepaliMonthMetadata {
  final int year;
  final int monthIndex; // 0-11
  final int daysInMonth;
  final String startDateAD; // YYYY-MM-DD
  final String endDateAD; // YYYY-MM-DD
  final int startDayOfWeek; // 0=Sunday, 6=Saturday

  const NepaliMonthMetadata({
    required this.year,
    required this.monthIndex,
    required this.daysInMonth,
    required this.startDateAD,
    required this.endDateAD,
    required this.startDayOfWeek,
  });
}

/// Precomputed mapping of Bikram Sambat (BS) years to their 12 month lengths (days).
/// Generated directly from the source Next.js project's nepali-date-converter library.
const Map<int, List<int>> nepaliMonthTable = {
`;

years.forEach(year => {
  dartCode += `  ${year}: [${yearMonthTable[year].join(', ')}],\n`;
});

dartCode += `};\n\n/// Precomputed list of all 60 months from BS 2080 to BS 2084 with Gregorian ranges.\n`;
dartCode += `const List<NepaliMonthMetadata> nepaliMonthMetadataList = [\n`;

result.forEach(m => {
  dartCode += `  NepaliMonthMetadata(\n`;
  dartCode += `    year: ${m.year},\n`;
  dartCode += `    monthIndex: ${m.monthIndex},\n`;
  dartCode += `    daysInMonth: ${m.daysInMonth},\n`;
  dartCode += `    startDateAD: '${m.startDateAD}',\n`;
  dartCode += `    endDateAD: '${m.endDateAD}',\n`;
  dartCode += `    startDayOfWeek: ${m.startDayOfWeek},\n`;
  dartCode += `  ),\n`;
});

dartCode += `];\n`;

fs.writeFileSync(dartOutputPath, dartCode, 'utf-8');

console.log(`Successfully generated ${result.length} months of golden data.`);
console.log(`JSON fixture: ${jsonOutputPath}`);
console.log(`Dart table: ${dartOutputPath}`);
