import axios from 'axios';
window.axios = axios;

window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

if (apiBaseUrl) {
    window.axios.defaults.baseURL = apiBaseUrl;
}

window.axios.defaults.withCredentials = import.meta.env.VITE_WITH_CREDENTIALS === 'true';
