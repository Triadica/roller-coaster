
{} (:package |app)
  :configs $ {} (:init-fn |app.main/main!) (:reload-fn |app.main/reload!) (:version |0.0.1)
    :modules $ [] |memof/ |quaternion/ |lagopus/
  :entries $ {}
  :files $ {}
    |app.comp.container $ {}
      :defs $ {}
        |comp-container $ quote
          defn comp-container (store)
            group nil (comp-ground)
              comp-cubes $ {} (:size 400)
        |comp-cubes $ quote
          defn comp-cubes (options)
            let
                size $ either (:size options) 200
                many 1000
              object $ {} (:shader cube-wgsl)
                :topology $ do :line-strip :triangle-list
                :attrs-list $ [] (:: :float32x3 :position)
                :data $ -> (range many)
                  map $ fn (idx)
                    let
                        base $ rand-pos 40000
                      []
                        :: :vertex $ v+ base ([] 0 0 0)
                        :: :vertex $ v+ base ([] 0 size 0)
                        :: :vertex $ v+ base ([] 0 size size)
                        :: :vertex $ v+ base ([] 0 0 size)
                        :: :vertex $ v+ base ([] size 0 0)
                        :: :vertex $ v+ base ([] size size 0)
                        :: :vertex $ v+ base ([] size size size)
                        :: :vertex $ v+ base ([] size 0 size)
                :indices $ -> (range many)
                  map $ fn (idx)
                    ->
                      [] ([] 0 1 2 0 2 3) ([] 0 1 5 0 4 5) ([] 1 2 6 1 6 5) ([] 2 3 6 3 6 7) ([] 0 3 4 3 4 7) ([] 4 5 6 4 6 7)
                      map $ fn (line)
                        map line $ fn (x)
                          + x $ * idx 8
        |comp-ground $ quote
          defn comp-ground () $ let
              y -10
              unit 600
            object $ {} (:shader ground-wgsl)
              :topology $ do :line-strip :triangle-list
              :attrs-list $ [] (:: :float32x3 :position)
              :data $ -> (range-bothway 50)
                map $ fn (i)
                  let
                      i+1 $ inc i
                    -> (range-bothway 50)
                      map $ fn (j)
                        let
                            j+1 $ inc j
                          []
                            : vertex $ [] (* unit i) y (* unit j)
                            : vertex $ [] (* unit i+1) y (* unit j)
                            : vertex $ [] (* unit i) y (* unit j+1)
                            : vertex $ [] (* unit i) y (* unit j+1)
                            : vertex $ [] (* unit i+1) y (* unit j)
                            : vertex $ [] (* unit i+1) y (* unit j+1)
        |rand-pos $ quote
          defn rand-pos (n)
            v-scale
              []
                - (js/Math.random) 0.5
                js/Math.random
                - (js/Math.random) 0.5
              , n
      :ns $ quote
        ns app.comp.container $ :require
          lagopus.alias :refer $ group object
          "\"../shaders/cube.wgsl" :default cube-wgsl
          "\"../shaders/ground.wgsl" :default ground-wgsl
          lagopus.comp.curves :refer $ comp-curves
          memof.once :refer $ memof1-call
          quaternion.core :refer $ c+ v+ v-scale
    |app.config $ {}
      :defs $ {}
        |dev? $ quote
          def dev? $ &= "\"dev" (get-env "\"mode" "\"release")
        |inline-shader $ quote
          defmacro inline-shader (path)
            read-file $ str "\"shaders/" path "\".wgsl"
        |remote-control? $ quote
          def remote-control? $ get-env "\"remote-control" nil
      :ns $ quote (ns app.config)
    |app.main $ {}
      :defs $ {}
        |*store $ quote
          defatom *store $ {} (:tab :cube)
        |canvas $ quote
          def canvas $ js/document.querySelector "\"canvas"
        |dispatch! $ quote
          defn dispatch! (op)
            if dev? $ js/console.log op
            let
                store @*store
                next-store $ tag-match op
                    :states cursor s
                    update-states store cursor s
                  (:tab t) (assoc store :tab t)
                  _ $ do (eprintln ":unknown op" op) store
              if (not= next-store store) (reset! *store next-store)
        |main! $ quote
          defn main! () (hint-fn async)
            if dev? $ load-console-formatter!
            js-await $ initializeContext
            initializeCanvasTextures
            reset-clear-color! $ either bg-color
              {} (:r 0.85) (:g 0.89) (:b 0.99) (:a 1)
            render-app!
            renderControl
            startControlLoop 10 onControlEvent
            set! js/window.__lagopusHandleCompilationInfo handle-compilation
            set! js/window.onresize $ fn (e) (resetCanvasSize canvas) (initializeCanvasTextures) (paintLagopusTree)
            resetCanvasSize canvas
            add-watch *store :change $ fn (next store) (render-app!)
            setupMouseEvents canvas
            if remote-control? $ setupRemoteControl
        |reload! $ quote
          defn reload! () $ if (nil? build-errors)
            do (reset-memof1-caches!) (render-app!) (remove-watch *store :change)
              add-watch *store :change $ fn (next store) (render-app!)
              println "\"Reloaded."
              hud! "\"ok~" "\"OK"
            hud! "\"error" build-errors
        |render-app! $ quote
          defn render-app! () $ let
              tree $ comp-container @*store
            renderLagopusTree tree dispatch!
      :ns $ quote
        ns app.main $ :require
          app.comp.container :refer $ comp-container
          "\"@triadica/lagopus" :refer $ setupMouseEvents onControlEvent paintLagopusTree renderLagopusTree initializeContext resetCanvasSize initializeCanvasTextures
          "\"@triadica/touch-control" :refer $ renderControl startControlLoop
          app.config :refer $ dev? remote-control?
          "\"bottom-tip" :default hud!
          "\"./calcit.build-errors" :default build-errors
          memof.once :refer $ reset-memof1-caches!
          lagopus.util :refer $ handle-compilation reset-clear-color!
          lagopus.cursor :refer $ update-states
          lagopus.config :refer $ bg-color
          "\"@triadica/lagopus/lib/remote-control.mjs" :refer $ setupRemoteControl
