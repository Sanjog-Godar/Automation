import { NextResponse } from 'next/server';

export async function GET() {
  const versionData = {
    version: '1.2.0',
    buildNumber: 3,
    releaseDate: '2026-11-21',
    apkUrl: 'https://vehiclemgmt.vercel.app/bolero-attendance.apk',
    releaseNotes: 'Bilingual Devanagari numbers, senior UI layout, high contrast status buttons, and permanent KM data protection.',
    releaseNotesNe: 'ठूला अक्षर, स्पष्ट बटन, नेपाली अंक र सुरक्षित किलोमिटर विवरण।',
  };

  return NextResponse.json(versionData, {
    headers: {
      'Cache-Control': 'no-store, max-age=0',
    },
  });
}

