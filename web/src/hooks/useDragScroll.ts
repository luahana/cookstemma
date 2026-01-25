import { useRef, useEffect } from 'react';

/**
 * Hook to enable click-and-drag horizontal scrolling
 */
export function useDragScroll<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const state = useRef({
    isDragging: false,
    startX: 0,
    scrollLeft: 0,
    hasMoved: false,
  });

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Apply styles to enable drag scrolling
    el.style.cursor = 'grab';
    el.style.userSelect = 'none';
    (el.style as unknown as Record<string, string>).webkitUserDrag = 'none';

    // Disable image dragging for all images inside
    const images = el.querySelectorAll('img');
    images.forEach((img) => {
      img.draggable = false;
    });

    const onMouseDown = (e: MouseEvent) => {
      // Only handle left mouse button
      if (e.button !== 0) return;

      state.current.isDragging = true;
      state.current.hasMoved = false;
      state.current.startX = e.pageX - el.offsetLeft;
      state.current.scrollLeft = el.scrollLeft;
      el.style.cursor = 'grabbing';
    };

    const onMouseMove = (e: MouseEvent) => {
      if (!state.current.isDragging) return;

      e.preventDefault();
      const x = e.pageX - el.offsetLeft;
      const walk = x - state.current.startX;

      // Mark as moved if dragged more than 5px
      if (Math.abs(walk) > 5) {
        state.current.hasMoved = true;
      }

      el.scrollLeft = state.current.scrollLeft - walk;
    };

    const onMouseUp = () => {
      if (!state.current.isDragging) return;
      state.current.isDragging = false;
      el.style.cursor = 'grab';
    };

    const onClick = (e: MouseEvent) => {
      // Prevent click on links if we were dragging
      if (state.current.hasMoved) {
        e.preventDefault();
        e.stopPropagation();
        state.current.hasMoved = false;
      }
    };

    // Prevent native image/link drag behavior
    const onDragStart = (e: DragEvent) => {
      e.preventDefault();
    };

    // Element listeners
    el.addEventListener('mousedown', onMouseDown);
    el.addEventListener('mousemove', onMouseMove);
    el.addEventListener('click', onClick, true);
    el.addEventListener('dragstart', onDragStart);

    // Window listeners for mouseup (catches release outside element)
    window.addEventListener('mouseup', onMouseUp);

    return () => {
      el.removeEventListener('mousedown', onMouseDown);
      el.removeEventListener('mousemove', onMouseMove);
      el.removeEventListener('click', onClick, true);
      el.removeEventListener('dragstart', onDragStart);
      window.removeEventListener('mouseup', onMouseUp);
    };
  }, []);

  return ref;
}
