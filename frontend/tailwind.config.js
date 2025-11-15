/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'alto': '#9b59b6',
        'baritone': '#27ae60',
        'standard': '#95a5a6',
        'all-keys': '#3498db',
      },
    },
  },
  plugins: [],
}
