Rails.application.routes.draw do
  # Rutas de autenticación
  devise_for :usuarios, controllers: {
    sessions: 'usuarios/sessions',
    registrations: 'usuarios/registrations'
  }

  # Ruta principal
  root 'home#index'

  # Rutas protegidas
  authenticate :usuario do
    get '/dashboard', to: 'dashboard#index', as: :dashboard

    # Perfil de usuario
    resource :perfil, only: %i[show edit update]
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
    end

    # Cursos y recursos anidados
    resources :cursos do
      member do
        post :inscribir_estudiante
        delete :desinscribir_estudiante
        get :estudiantes
        get :metricas
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
