import React, { useState, useEffect } from 'react';
import { applications, Application } from '../api/auth';

const ApplicationManager: React.FC = () => {
  const [apps, setApps] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingApp, setEditingApp] = useState<Application | null>(null);
  const [formData, setFormData] = useState({ name: '', description: '' });

  useEffect(() => {
    loadApplications();
  }, []);

  const loadApplications = async () => {
    try {
      setLoading(true);
      const data = await applications.getAll();
      setApps(data);
    } catch (err) {
      setError('Failed to load applications');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingApp) {
        await applications.update(editingApp.id, formData.name, formData.description);
      } else {
        await applications.create(formData.name, formData.description);
      }
      setShowForm(false);
      setEditingApp(null);
      setFormData({ name: '', description: '' });
      loadApplications();
    } catch (err) {
      setError('Failed to save application');
    }
  };

  const handleEdit = (app: Application) => {
    setEditingApp(app);
    setFormData({ name: app.name, description: app.description });
    setShowForm(true);
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this application?')) {
      try {
        await applications.delete(id);
        loadApplications();
      } catch (err) {
        setError('Failed to delete application');
      }
    }
  };

  const handleNewApp = () => {
    setEditingApp(null);
    setFormData({ name: '', description: '' });
    setShowForm(true);
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h2>My Applications</h2>
        <button onClick={handleNewApp} style={styles.primaryButton}>
          Create New Application
        </button>
      </div>

      {error && <div style={styles.error}>{error}</div>}

      {showForm && (
        <div style={styles.modal}>
          <div style={styles.modalContent}>
            <h3>{editingApp ? 'Edit Application' : 'New Application'}</h3>
            <form onSubmit={handleSubmit}>
              <input
                type="text"
                placeholder="Application Name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                style={styles.input}
              />
              <textarea
                placeholder="Description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                style={{ ...styles.input, minHeight: '100px' }}
              />
              <div style={styles.buttonGroup}>
                <button type="submit" style={styles.primaryButton}>
                  {editingApp ? 'Update' : 'Create'}
                </button>
                <button
                  type="button"
                  onClick={() => setShowForm(false)}
                  style={styles.secondaryButton}
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div style={styles.appGrid}>
        {apps.map((app) => (
          <div key={app.id} style={styles.appCard}>
            <h3>{app.name}</h3>
            <p>{app.description}</p>
            <div style={styles.apiKeyContainer}>
              <small>API Key:</small>
              <code style={styles.apiKey}>{app.api_key}</code>
            </div>
            <div style={styles.cardFooter}>
              <small>Created: {new Date(app.created_at).toLocaleDateString()}</small>
              <div>
                <button
                  onClick={() => handleEdit(app)}
                  style={styles.editButton}
                >
                  Edit
                </button>
                <button
                  onClick={() => handleDelete(app.id)}
                  style={styles.deleteButton}
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {apps.length === 0 && (
        <div style={styles.emptyState}>
          <p>No applications yet. Create your first application!</p>
        </div>
      )}
    </div>
  );
};

const styles: { [key: string]: React.CSSProperties } = {
  container: {
    padding: '2rem',
    maxWidth: '1200px',
    margin: '0 auto',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '2rem',
  },
  appGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
    gap: '1.5rem',
  },
  appCard: {
    backgroundColor: 'white',
    border: '1px solid #ddd',
    borderRadius: '8px',
    padding: '1.5rem',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
  },
  apiKeyContainer: {
    margin: '1rem 0',
  },
  apiKey: {
    display: 'block',
    padding: '0.5rem',
    backgroundColor: '#f5f5f5',
    borderRadius: '4px',
    fontSize: '0.85rem',
    wordBreak: 'break-all',
    marginTop: '0.25rem',
  },
  cardFooter: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: '1rem',
    paddingTop: '1rem',
    borderTop: '1px solid #eee',
  },
  primaryButton: {
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    padding: '0.75rem 1.5rem',
    borderRadius: '4px',
    cursor: 'pointer',
    fontSize: '1rem',
  },
  secondaryButton: {
    backgroundColor: '#6c757d',
    color: 'white',
    border: 'none',
    padding: '0.75rem 1.5rem',
    borderRadius: '4px',
    cursor: 'pointer',
    fontSize: '1rem',
  },
  editButton: {
    backgroundColor: '#28a745',
    color: 'white',
    border: 'none',
    padding: '0.5rem 1rem',
    borderRadius: '4px',
    cursor: 'pointer',
    marginRight: '0.5rem',
  },
  deleteButton: {
    backgroundColor: '#dc3545',
    color: 'white',
    border: 'none',
    padding: '0.5rem 1rem',
    borderRadius: '4px',
    cursor: 'pointer',
  },
  modal: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.5)',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  modalContent: {
    backgroundColor: 'white',
    padding: '2rem',
    borderRadius: '8px',
    width: '90%',
    maxWidth: '500px',
  },
  input: {
    width: '100%',
    padding: '0.75rem',
    marginBottom: '1rem',
    border: '1px solid #ddd',
    borderRadius: '4px',
    fontSize: '1rem',
    boxSizing: 'border-box',
  },
  buttonGroup: {
    display: 'flex',
    gap: '1rem',
    justifyContent: 'flex-end',
  },
  error: {
    color: '#dc3545',
    padding: '1rem',
    backgroundColor: '#f8d7da',
    border: '1px solid #f5c6cb',
    borderRadius: '4px',
    marginBottom: '1rem',
  },
  emptyState: {
    textAlign: 'center',
    padding: '3rem',
    color: '#6c757d',
  },
};

export default ApplicationManager;