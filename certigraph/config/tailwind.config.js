module.exports = {
    darkMode: 'class',
    content: [
        './app/views/**/*.html.erb',
        './app/helpers/**/*.rb',
        './app/assets/stylesheets/**/*.css',
        './app/javascript/**/*.js'
    ],
    theme: {
        extend: {
            colors: {
                primary: {
                    DEFAULT: '#137fec',
                    hover: '#0f6dd4',
                    light: 'rgba(19, 127, 236, 0.1)',
                },
                background: {
                    light: '#f6f7f8',
                    dark: '#101922',
                },
                surface: {
                    dark: '#1e293b',
                    light: '#ffffff',
                },
                border: {
                    dark: '#334155',
                    light: '#e7edf3',
                },
                success: '#10b981',
                warning: '#f59e0b',
                danger: '#ef4444',
                info: '#3b82f6',
            },
            fontFamily: {
                display: ['Space Grotesk', 'Noto Sans KR', 'sans-serif'],
                sans: ['Noto Sans KR', 'sans-serif'],
                serif: ['Noto Serif KR', 'serif'],
            },
            fontSize: {
                'xs': '10px',
                'sm': '12px',
                'base': '14px',
                'md': '16px',
                'lg': '18px',
                'xl': '20px',
                '2xl': '24px',
                '3xl': '30px',
                '4xl': '40px',
            },
            spacing: {
                '0': '0',
                '1': '4px',
                '2': '8px',
                '3': '12px',
                '4': '16px',
                '5': '20px',
                '6': '24px',
                '8': '32px',
                '10': '40px',
                '12': '48px',
                '16': '64px',
            },
            borderRadius: {
                'sm': '4px',
                'DEFAULT': '8px',
                'md': '8px',
                'lg': '12px',
                'xl': '16px',
                '2xl': '24px',
                'full': '9999px',
            },
            boxShadow: {
                'sm': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
                'DEFAULT': '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                'md': '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                'lg': '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
                'xl': '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
                '2xl': '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
                'primary': '0 10px 20px rgba(19, 127, 236, 0.2)',
            },
            backdropBlur: {
                'xs': '2px',
                'sm': '4px',
                'DEFAULT': '8px',
                'md': '12px',
                'lg': '16px',
                'xl': '24px',
            },
        },
    },
    plugins: [
        require('@tailwindcss/forms'),
    ],
}
