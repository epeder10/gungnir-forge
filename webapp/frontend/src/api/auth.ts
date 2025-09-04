import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export interface User {
  id: number;
  username: string;
  email: string;
}

export interface Application {
  id: number;
  name: string;
  description: string;
  api_key: string;
  created_at: string;
}

export const auth = {
  register: async (username: string, email: string, password: string) => {
    const response = await api.post('/register', { username, email, password });
    if (response.data.token) {
      localStorage.setItem('token', response.data.token);
    }
    return response.data;
  },

  login: async (username: string, password: string) => {
    const response = await api.post('/login', { username, password });
    if (response.data.token) {
      localStorage.setItem('token', response.data.token);
    }
    return response.data;
  },

  logout: () => {
    localStorage.removeItem('token');
  },

  getCurrentUser: async () => {
    const response = await api.get('/user');
    return response.data;
  },
};

export const applications = {
  getAll: async (): Promise<Application[]> => {
    const response = await api.get('/applications');
    return response.data;
  },

  create: async (name: string, description: string): Promise<Application> => {
    const response = await api.post('/applications', { name, description });
    return response.data;
  },

  update: async (id: number, name: string, description: string): Promise<Application> => {
    const response = await api.put(`/applications/${id}`, { name, description });
    return response.data;
  },

  delete: async (id: number): Promise<void> => {
    await api.delete(`/applications/${id}`);
  },
};