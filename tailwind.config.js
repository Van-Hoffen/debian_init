/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        mono: ['"JetBrains Mono"', 'Menlo', 'Monaco', 'Consolas', '"Liberation Mono"', '"Courier New"', 'monospace'],
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      colors: {
        term: {
          bg: '#0d1117',
          header: '#161b22',
          border: '#30363d',
          red: '#f85149',
          green: '#7ee787',
          yellow: '#f2cc60',
          blue: '#58a6ff',
          purple: '#bc8cff',
          orange: '#ffa657',
          gray: '#8b949e',
          teal: '#01696f',
        }
      }
    },
  },
  plugins: [],
}
