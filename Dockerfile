FROM prestashop/prestashop:8.0.1
RUN mkdir -p /tmp/post-install-scripts
COPY --chown=www-data:www-data shop1_post_install/* /tmp/post-install-scripts/

CMD ["/tmp/docker_run.sh"]