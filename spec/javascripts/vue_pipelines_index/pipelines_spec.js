import Vue from 'vue';
import pipelinesComp from '~/vue_pipelines_index/pipelines';
import Store from '~/vue_pipelines_index/stores/pipelines_store';
import pipelinesData from './mock_data';

describe('Pipelines', () => {
  preloadFixtures('static/pipelines.html.raw');

  let PipelinesComponent;

  beforeEach(() => {
    loadFixtures('static/pipelines.html.raw');

    PipelinesComponent = Vue.extend(pipelinesComp);
  });

  describe('successfull request', () => {
    describe('with pipelines', () => {
      const pipelinesInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify(pipelinesData), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(pipelinesInterceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesInterceptor,
        );
      });

      it('should render table', (done) => {
        const component = new PipelinesComponent({
          propsData: {
            store: new Store(),
          },
        }).$mount();

        setTimeout(() => {
          expect(component.$el.querySelector('.table-holder')).toBeDefined();
          expect(component.$el.querySelector('.realtime-loading')).toBe(null);
          done();
        });
      });
    });

    describe('without pipelines', () => {
      const emptyInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(emptyInterceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, emptyInterceptor,
        );
      });

      it('should render empty state', (done) => {
        const component = new PipelinesComponent({
          propsData: {
            store: new Store(),
          },
        }).$mount();

        setTimeout(() => {
          expect(component.$el.querySelector('.empty-state')).toBeDefined();
          expect(component.$el.querySelector('.realtime-loading')).toBe(null);
          done();
        });
      });
    });
  });

  describe('unsuccessfull request', () => {
    const errorInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 500,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(errorInterceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, errorInterceptor,
      );
    });

    it('should render error state', (done) => {
      const component = new PipelinesComponent({
        propsData: {
          store: new Store(),
        },
      }).$mount();

      setTimeout(() => {
        expect(component.$el.querySelector('.js-pipelines-error-state')).toBeDefined();
        expect(component.$el.querySelector('.realtime-loading')).toBe(null);
        done();
      });
    });
  });
});
