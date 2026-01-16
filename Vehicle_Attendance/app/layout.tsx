import type { Metadata } from 'next';
import './globals.css';
import { QueryProvider } from '@/components/QueryProvider';
import { Mukta } from 'next/font/google';

const mukta = Mukta({ 
  weight: ['400', '600', '700'],
  subsets: ['devanagari', 'latin'],
  variable: '--font-mukta',
});

export const metadata: Metadata = {
  title: 'Vehicle Attendance & Earnings Tracker',
  description: 'Track daily attendance and monthly income for Jeep driver',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={mukta.variable}>
        <QueryProvider>{children}</QueryProvider>
      </body>
    </html>
  );
}
