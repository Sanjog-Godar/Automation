import { NextResponse } from 'next/server';

export async function GET() {
  const versionData = {
    "version": "1.2.1",
    "buildNumber": 4,
    "releaseDate": "2026-11-21",
    "apkUrl": "https://vehiclemgmt.vercel.app/bolero-attendance.apk",
    "releaseNotes": "Bug fixes and performance improvements (v1.2.1)",
    "releaseNotesNe": "सुधारहरू र नयाँ सुविधाहरू (v1.2.1)"
};

  return NextResponse.json(versionData, {
    headers: {
      'Cache-Control': 'no-store, max-age=0',
    },
  });
}
