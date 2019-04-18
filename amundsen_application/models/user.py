from typing import Dict

from marshmallow import Schema, fields, pre_load, post_load, validates_schema, ValidationError

from flask import Response, jsonify
from flask import current_app as app


"""
TODO: Explore all internationalization use cases and
redesign how User handles names
"""


class User:
    def __init__(self,
                 email: str = None,
                 employee_type: str = None,
                 first_name: str = None,
                 full_name: str = None,
                 github_username: str = None,
                 is_active: bool = True,
                 last_name: str = None,
                 manager_fullname: str = None,
                 profile_url: str = None,
                 role_name: str = None,
                 slack_id: str = None,
                 team_name: str = None,
                 user_id: str = None) -> None:
        self.email = email
        self.employee_type = employee_type
        self.first_name = first_name
        self.full_name = full_name
        self.github_username = github_username
        self.is_active = is_active
        self.last_name = last_name
        self.manager_fullname = manager_fullname
        self.profile_url = profile_url
        self.role_name = role_name
        self.slack_id = slack_id
        self.team_name = team_name
        self.user_id = user_id
        # TODO: Add frequent_used, bookmarked, & owned resources

    def to_json(self) -> Response:
        user_info = dump_user(self)
        return jsonify(user_info)


class UserSchema(Schema):
    email = fields.Str()
    employee_type = fields.Str()
    first_name = fields.Str()
    full_name = fields.Str()
    github_username = fields.Str()
    is_active = fields.Bool()
    last_name = fields.Str()
    manager_fullname = fields.Str()
    profile_url = fields.Str()
    role_name = fields.Str()
    slack_id = fields.Str()
    team_name = fields.Str()
    user_id = fields.Str(required=True)

    @pre_load
    def preprocess_data(self, data: Dict) -> Dict:
        if not data.get('user_id', None):
            data['user_id'] = data.get('email', None)

        if not data.get('profile_url', None):
            data['profile_url'] = ''
            if app.config['GET_PROFILE_URL']:
                data['profile_url'] = app.config['GET_PROFILE_URL'](data['user_id'])

        if not data.get('full_name', None):
            data['full_name'] = '{} {}'.format(data.get('first_name', ''), data.get('last_name', '')).strip()

        return data

    @post_load
    def make_user(self, data: Dict) -> User:
        return User(**data)

    @validates_schema
    def validate_user(self, data: Dict) -> None:
        if not data.get('user_id', None):
            raise ValidationError('"user_id" must be provided')


def load_user(user_data: Dict) -> User:
    try:
        schema = UserSchema()
        data, errors = schema.load(user_data)
        return data
    except ValidationError as err:
        return err.messages


def dump_user(user: User) -> Dict:
    schema = UserSchema()
    try:
        data, errors = schema.dump(user)
        return data
    except ValidationError as err:
        return err.messages
