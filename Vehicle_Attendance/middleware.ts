import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Simple auth middleware based on our own login cookie.
// We treat presence of `sb-access-token` as "logged in".
export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const isLoginPage = pathname === '/login';
  const hasAuthCookie = req.cookies.has('sb-access-token');

  // Not logged in and trying to access any protected route -> go to /login
  if (!hasAuthCookie && !isLoginPage) {
    return NextResponse.redirect(new URL('/login', req.url));
  }

  // Already logged in and trying to access /login -> go to home
  if (hasAuthCookie && isLoginPage) {
    return NextResponse.redirect(new URL('/', req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
