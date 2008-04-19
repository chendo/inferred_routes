# lib/inferred_routes.rb
#
# Version 0.2.0
#
# David A. Black
#
# April 19, 2008
#
# This is simply the define_url_helper method from ActionController,
# with a big hack from me to make it infer routes.

      class ActionController::Routing::RouteSet::NamedRouteCollection 
          def define_url_helper(route, name, kind, options)
            selector = url_helper_name(name, kind) 
            hash_access_method = hash_access_name(name, kind)
      
            @module.module_eval <<-end_eval # We use module_eval to avoid leaks
              def #{selector}(*args)
                #{generate_optimisation_block(route, kind)}

                keys = #{route.segment_keys.inspect}
                opts = if args.empty? || Hash === args.first
                  args.first || {}
                else
                  options = args.last.is_a?(Hash) ? args.pop : {}

                sing = keys[-1] == :id
                items = keys.map {|k| k.to_s[/[^_]+/] }

                if sing
                  items.pop
                  until args.size == keys.size
                    args.unshift(args[0].send(items.pop))
                  end
                else
                  if args.size == 1
# items: ["scratchpad","page"]
# args:  [@page]
                    if args[0].class.name == items[-1].classify
                      base_obj = args[0]
                      items.pop
                    else
# items: ["scratchpad", "page"]
# args:  [@idea]
                      base_obj = args.shift
                    end
                    items.reverse.each do |item|
                      args.unshift(base_obj.send(item))
                      base_obj = args[0]
                    end
                  end
                end
                args = args.zip(#{route.segment_keys.inspect}).inject({}) do |h, (v, k)|
                  v ||= ""
                  h[k] = v
                  h
                end
                options.merge(args)
              end
              url_for(#{hash_access_method}(opts))
            end
            protected :#{selector}
          end_eval
          helpers << selector
        end
      end
