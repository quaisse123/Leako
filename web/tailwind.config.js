/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Palette OCP (alignée avec l'app mobile)
        ocp: {
          green: '#00875a',
          dark: '#005c3e',
          black: '#111111',
          grey: '#757575',
          'light-grey': '#f5f5f5',
        },
        primary: {
          50: '#ecfdf5',
          100: '#d1fae5',
          200: '#a7f3d0',
          300: '#6ee7b7',
          400: '#34d399',
          500: '#10b981',
          600: '#00875a',
          700: '#005c3e',
          800: '#064e3b',
          900: '#064e3b',
        },
        surface: {
          DEFAULT: '#ffffff',
          dark: '#f5f5f5',
          card: '#ffffff',
          hover: '#f0f4f2',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
