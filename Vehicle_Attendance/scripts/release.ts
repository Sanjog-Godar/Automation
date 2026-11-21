import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const rootDir = path.resolve(__dirname, '..');
const flutterDir = path.join(rootDir, 'Flutter App', 'vehicle_app');
const pubspecPath = path.join(flutterDir, 'pubspec.yaml');
const appConfigPath = path.join(flutterDir, 'lib', 'core', 'config', 'app_config.dart');
const appDrawerPath = path.join(flutterDir, 'lib', 'features', 'attendance', 'widgets', 'app_drawer.dart');
const versionJsonPath = path.join(rootDir, 'public', 'version.json');
const versionRoutePath = path.join(rootDir, 'app', 'api', 'app-version', 'route.ts');
const releaseApkPath = path.join(flutterDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
const publicApkPath = path.join(rootDir, 'public', 'bolero-attendance.apk');

function run(cmd: string, cwd: string = rootDir) {
  console.log(`\n> [EXEC] ${cmd} (in ${cwd})`);
  execSync(cmd, { cwd, stdio: 'inherit' });
}

function main() {
  console.log('========================================================');
  console.log('🚀 AUTOMATED RELEASE & DEPLOY PIPELINE');
  console.log('========================================================');

  // 1. Read current version from pubspec.yaml
  const pubspecContent = fs.readFileSync(pubspecPath, 'utf8');
  const versionMatch = pubspecContent.match(/version:\s*([0-9.]+)\+([0-9]+)/);
  if (!versionMatch) {
    throw new Error('Could not find version: x.y.z+build in pubspec.yaml');
  }

  const currentVersion = versionMatch[1];
  const currentBuild = parseInt(versionMatch[2], 10);

  // Command-line arguments: [node, script, newVersion?, ...notes]
  const args = process.argv.slice(2);
  let newVersion = '';
  let releaseNotes = '';

  if (args.length > 0 && /^[0-9]+\.[0-9]+\.[0-9]+$/.test(args[0])) {
    newVersion = args[0];
    releaseNotes = args.slice(1).join(' ');
  } else {
    // Auto-bump patch version: 1.2.0 -> 1.2.1
    const parts = currentVersion.split('.').map((n) => parseInt(n, 10));
    parts[2] = (parts[2] || 0) + 1;
    newVersion = parts.join('.');
    releaseNotes = args.join(' ');
  }

  const newBuild = currentBuild + 1;
  const today = new Date().toISOString().substring(0, 10);

  if (!releaseNotes.trim()) {
    releaseNotes = `Bug fixes and performance improvements (v${newVersion})`;
  }

  console.log(`\n📌 Upgrading Version:`);
  console.log(`   Previous : v${currentVersion} (Build ${currentBuild})`);
  console.log(`   New      : v${newVersion} (Build ${newBuild})`);
  console.log(`   Notes    : ${releaseNotes}\n`);

  // 2. Update pubspec.yaml
  const updatedPubspec = pubspecContent.replace(
    /version:\s*[0-9.]+\+[0-9]+/,
    `version: ${newVersion}+${newBuild}`
  );
  fs.writeFileSync(pubspecPath, updatedPubspec, 'utf8');
  console.log(`✓ Updated pubspec.yaml -> version: ${newVersion}+${newBuild}`);

  // 3. Update app_config.dart
  if (fs.existsSync(appConfigPath)) {
    let appConfig = fs.readFileSync(appConfigPath, 'utf8');
    appConfig = appConfig.replace(
      /static const String currentVersion = '[^']+';/,
      `static const String currentVersion = '${newVersion}';`
    );
    appConfig = appConfig.replace(
      /static const int currentBuildNumber = \d+;/,
      `static const int currentBuildNumber = ${newBuild};`
    );
    fs.writeFileSync(appConfigPath, appConfig, 'utf8');
    console.log(`✓ Updated app_config.dart -> ${newVersion} (${newBuild})`);
  }

  // 4. Update app_drawer.dart display string
  if (fs.existsSync(appDrawerPath)) {
    let appDrawer = fs.readFileSync(appDrawerPath, 'utf8');
    appDrawer = appDrawer.replace(
      /'v[0-9.]+\s*•\s*Mukta Font'/,
      `'v${newVersion} • Mukta Font'`
    );
    fs.writeFileSync(appDrawerPath, appDrawer, 'utf8');
    console.log(`✓ Updated app_drawer.dart -> v${newVersion} • Mukta Font`);
  }

  // 5. Update public/version.json
  const versionData = {
    version: newVersion,
    buildNumber: newBuild,
    releaseDate: today,
    apkUrl: 'https://vehiclemgmt.vercel.app/bolero-attendance.apk',
    releaseNotes: releaseNotes,
    releaseNotesNe: `सुधारहरू र नयाँ सुविधाहरू (v${newVersion})`,
  };
  fs.writeFileSync(versionJsonPath, JSON.stringify(versionData, null, 2) + '\n', 'utf8');
  console.log(`✓ Updated public/version.json`);

  // 6. Update app/api/app-version/route.ts
  if (fs.existsSync(versionRoutePath)) {
    const routeContent = `import { NextResponse } from 'next/server';

export async function GET() {
  const versionData = ${JSON.stringify(versionData, null, 4)};

  return NextResponse.json(versionData, {
    headers: {
      'Cache-Control': 'no-store, max-age=0',
    },
  });
}
`;
    fs.writeFileSync(versionRoutePath, routeContent, 'utf8');
    console.log(`✓ Updated app/api/app-version/route.ts`);
  }

  // 7. Compile Release APK
  console.log('\n🔨 Building Flutter release APK...');
  run('flutter build apk --release', flutterDir);

  // 8. Copy to public/bolero-attendance.apk
  if (!fs.existsSync(releaseApkPath)) {
    throw new Error(`Build finished but APK was not found at ${releaseApkPath}`);
  }
  fs.copyFileSync(releaseApkPath, publicApkPath);
  const stats = fs.statSync(publicApkPath);
  const sizeMb = (stats.size / (1024 * 1024)).toFixed(1);
  console.log(`✓ Copied APK to public/bolero-attendance.apk (${sizeMb} MB)`);

  // 9. Git Commit and Push to Deploy
  console.log('\n📦 Committing and Pushing to trigger Vercel deployment...');
  run('git add -A', rootDir);
  try {
    run(`git commit -m "release: v${newVersion} (build ${newBuild}) - ${releaseNotes}"`, rootDir);
  } catch {
    console.log('No new changes to commit.');
  }

  console.log('\n🚀 Pushing to origin/main...');
  try {
    run('git push origin main', rootDir);
    console.log('✓ Successfully pushed to origin main! Vercel is deploying now.');
  } catch (err: any) {
    console.warn('⚠️ git push failed or origin not reachable. You can push manually using: git push');
  }

  // 10. Optional ADB auto-install if a device is connected
  try {
    const adbOutput = execSync('adb devices', { encoding: 'utf8' });
    const hasDevice = adbOutput
      .split('\n')
      .slice(1)
      .some((line) => line.trim().endsWith('device'));

    if (hasDevice) {
      console.log('\n📱 Connected Android device detected via ADB! Installing release APK directly...');
      run(`adb install -r "${publicApkPath}"`, rootDir);
      console.log('✓ Release APK successfully installed to connected phone!');
    }
  } catch {}

  console.log('\n========================================================');
  console.log(`🎉 RELEASE COMPLETE: v${newVersion} (Build ${newBuild})`);
  console.log(`   - APK Link: https://vehiclemgmt.vercel.app/bolero-attendance.apk`);
  console.log(`   - Version Endpoint: https://vehiclemgmt.vercel.app/version.json`);
  console.log(`   - Phones running Bolero Attendance will auto-update on launch!`);
  console.log('========================================================\n');
}

main();
