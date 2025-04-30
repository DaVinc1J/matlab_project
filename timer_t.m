function timer_t()
    t = timer('ExecutionMode', 'fixedRate', ...
              'Period', 1, ... 
              'TimerFcn', @timer_callback); 

    start(t);

    uiwait(gcf);

    stop(t);
    delete(t);
end

function timer_callback(~, ~)
    disp('Timer ticked!');
end
