// Quick test to verify the Social Worker exam date
const socialWorkerDates = [
  { year: 2023, round: 21, date: new Date(2023, 1, 11), registration: new Date(2022, 11, 12) },
  { year: 2024, round: 22, date: new Date(2024, 1, 3), registration: new Date(2023, 11, 4) },
  { year: 2025, round: 23, date: new Date(2025, 1, 8), registration: new Date(2024, 11, 9) },
  { year: 2026, round: 19, date: new Date(2026, 0, 17), registration: new Date(2025, 11, 15) },  // 1월 17일
];

const exam2026 = socialWorkerDates[3];
console.log('2026 Social Worker Exam:');
console.log('  Date object:', exam2026.date);
console.log('  Year:', exam2026.date.getFullYear());
console.log('  Month (0-indexed):', exam2026.date.getMonth());
console.log('  Month (human):', exam2026.date.getMonth() + 1);
console.log('  Day:', exam2026.date.getDate());
console.log('  ISO String:', exam2026.date.toISOString());
console.log('  Local String:', exam2026.date.toLocaleDateString('ko-KR'));

// Test filtering logic
const today = new Date();
const oneYearAgo = new Date(today);
oneYearAgo.setFullYear(today.getFullYear() - 1);
const twoYearsLater = new Date(today);
twoYearsLater.setFullYear(today.getFullYear() + 2);

console.log('\nToday:', today.toISOString());
console.log('One year ago:', oneYearAgo.toISOString());
console.log('Two years later:', twoYearsLater.toISOString());
console.log('Passes filter?', exam2026.date >= oneYearAgo && exam2026.date <= twoYearsLater);
