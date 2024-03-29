begin;

create extension "basejump-supabase_test_helpers" version '0.0.6';

select
  no_plan();

select
  tests.create_supabase_user('user');

select
  tests.authenticate_as('user');

select
  lives_ok($$
    select
      create_new_organization('Supabase');

$$);

set local role service_role;

select
  (lives_ok($$ insert into subscriptions(
        cancel_at_period_end, price_id, id, status)
      values (
        true, '1', '1', 'incomplete');

$$,
'can insert a subscription as an admin'));

select
  (lives_ok($$ insert into organizations_subscriptions(
        organization_id, subscription_id, customer_id)
      values (
        makerkit.get_organization_id(
          'Supabase'), '1', '1');

$$,
'can insert an organization subscription as an admin'));

select
  tests.authenticate_as('user');

select
  (throws_ok($$ insert into subscriptions(
        price_id, id, status)
      values (
        '1', '1', 'active');

$$,
'new row violates row-level security policy for table "subscriptions"'));

select
  isnt_empty($$
    select
      * from subscriptions
      where
        id = '1' $$, 'an user can read a subscription if it belongs to the same organization');

select
  isnt_empty($$
    select
      * from organizations_subscriptions
      where
        subscription_id = '1' $$, 'an user can read an organization subscription if it does belong to the same organization');

select
  tests.create_supabase_user('user-2');

select
  tests.authenticate_as('user-2');

select
  is_empty($$
    select
      * from subscriptions
      where
        id = '1' $$, 'an user cannot read a subscription if it does not belong to the same organization');

select
  is_empty($$
    select
      * from organizations_subscriptions
      where
        subscription_id = '1' $$, 'an user cannot read an organization subscription if it does not belong to the same organization');

select
  *
from
  finish();

rollback;
