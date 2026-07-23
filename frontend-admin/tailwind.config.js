/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'deep-teal': '#032F2F',
        'dark-teal': '#043B3B',
        'dark-green': '#052C2E',
        'genesis-card': '#083F40',
        'genesis-card-sec': '#0A4848',
        'dorado': '#D4AF37',
        'dorado-light': '#F2C66D',
        'crema': '#F8F1E4',
        'exito': '#22C55E',
        'error-red': '#EF4444',
        'advertencia': '#F59E0B',
      },
      fontFamily: {
        sans: ['Outfit', 'Inter', 'sans-serif'],
      },
      boxShadow: {
        'premium': '0 4px 30px rgba(0, 0, 0, 0.4)',
        'glass': '0 8px 32px 0 rgba(3, 47, 47, 0.37)',
      },
    },
  },
  plugins: [],
}
