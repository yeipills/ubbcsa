Rails.application.routes.draw do
  # Rutas de autenticación
  devise_for :usuarios, controllers: {
    sessions: 'usuarios/sessions',
    registrations: 'usuarios/registrations'
  }

  # Ruta principal
  root 'home#index'

  # API para terminal y Wetty
  namespace :api do
    post '/validate_wetty_token', to: 'terminal#validate_token'
    get '/terminal/metrics', to: 'terminal#metrics'
    post '/terminal/command', to: 'terminal#command'
    # Nuevos endpoints para máquinas objetivo
    post '/terminal/execute_on_target', to: 'terminal#execute_on_target'
    post '/terminal/deploy_target', to: 'terminal#deploy_target'
    post '/terminal/restart_target', to: 'terminal#restart_target'
    get '/terminal/list_targets', to: 'terminal#list_targets'
    # Asegurar que la validación de token sea accesible sin autenticación con ambos métodos
    post '/terminal/validate_token', to: 'terminal#validate_token'
    get '/terminal/validate_token', to: 'terminal#validate_token'
  end

  # Rutas protegidas
  authenticate :usuario do
    get '/dashboard', to: 'dashboard#index', as: :dashboard

    # Perfil de usuario
    resources :perfil, only: %i[show edit update]
    get 'mi_perfil', to: 'mi_perfil#show', as: 'mi_perfil'
    get 'mi_perfil/edit', to: 'mi_perfil#edit', as: 'edit_mi_perfil'
    patch 'mi_perfil', to: 'mi_perfil#update'

    # Sesiones de laboratorio y consola
    resources :sesion_laboratorios do
      member do
        post :reset
        post :pausar
        post :completar
      end

      resource :consola, only: [:show] do
        get 'terminal', to: 'wetty#show'
      end

      # NUEVO: Ejercicios dentro de una sesión
      resources :ejercicios, only: [:show] do
        member do
          post :verificar
        end
      end
    end

    # Cursos y recursos anidados
    resources :cursos do
      member do
        post :inscribir_estudiante
        delete :desinscribir_estudiante
        get :estudiantes
        get :metricas
      end
      
      collection do
        get :buscar
      end
      
      # Gestión de estudiantes
      resources :estudiantes, controller: 'cursos/estudiantes', only: [] do
        collection do
          post :add
          delete :remove
        end
      end

      # Laboratorios anidados con shallow routing
      resources :laboratorios, shallow: true

      # Quizzes anidados con shallow routing
      resources :quizzes, shallow: true do
        resources :preguntas, controller: 'quiz_preguntas', shallow: true do
          resources :opciones, controller: 'quiz_opciones', shallow: true

          collection do
            post :reordenar
          end
        end

        resources :intentos, controller: 'intentos_quiz', shallow: true do
          member do
            post :iniciar
            post :finalizar
            get :resultados
            post :responder
            post :registrar_evento  # Nueva ruta para registrar eventos de seguridad
          end
        end

        member do
          post :publicar
          post :despublicar
          post :duplicate
          get :estadisticas
          get :exportar_resultados  # Nueva ruta para exportar resultados
        end
      end
    end

    # Laboratorios independientes
    resources :laboratorios, only: %i[index show] do
      collection do
        get :disponibles
        get :completados
      end

      # NUEVO: Ejercicios asociados a un laboratorio
      resources :ejercicios
    end

    # Quizzes independientes (vista general)
    resources :quizzes, only: %i[index show] do
      resources :intentos, controller: 'intentos_quiz', only: %i[create show update] do
        member do
          post :finalizar
          get :resultados
          post :registrar_evento # También aquí para mantener coherencia
        end
      end

      member do
        get :exportar_resultados, format: %i[csv pdf] # Con formatos específicos
      end
    end

    # Reportes
    resources :reportes, only: %i[index show] do
      collection do
        get :descargar
      end
    end

    # NUEVO: Rutas para Progreso Dashboard
    get '/progreso', to: 'progreso#index', as: 'progreso'
    get '/progreso/chart_data', to: 'progreso#chart_data', as: 'progreso_chart_data'
    get '/progreso/detalles_laboratorio/:id', to: 'progreso#detalles_laboratorio', as: 'detalles_laboratorio'
    get '/progreso/detalles_curso/:id', to: 'progreso#detalles_curso', as: 'detalles_curso'
    get '/progreso/estudiante/:id', to: 'progreso#estudiante', as: 'progreso_estudiante'
    get '/progreso/exportar_pdf', to: 'progreso#exportar_pdf', as: 'progreso_exportar_pdf'

    # NUEVO: Sistema de notificaciones
    resources :notificaciones, only: %i[index show] do
      collection do
        get :no_leidas
        post :marcar_todas_como_leidas
        delete :eliminar_todas
        get :preferencias
        post :preferencias
      end

      member do
        post :marcar_como_leida
        post :marcar_como_no_leida
        delete :eliminar, as: :eliminar
      end
    end

    # Panel de administración
    namespace :admin do
      get '/', to: 'dashboard#index'
      resources :usuarios
      resources :cursos
      resources :laboratorios
      resources :configuracion, only: %i[index update]
      resources :monitor, only: %i[index show]
      resources :reportes, only: %i[index show]
    end
  end
end
