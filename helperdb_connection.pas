import datetime
import hashlib
import sys

import yaml
from sqlalchemy import MetaData, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


class DBConnection:
    def __init__(self, config_path, schema):
        self.__db_config = self.__load_config(config_path)
        try:
            self.__db_user = self.__db_config.get('db_user')
            self.__db_passwd = self.__db_config.get('db_passwd')
            self.__db_name = self.__db_config.get('db_name')
            self.__db_host = self.__db_config.get('db_host')
            self.__db_port = self.__db_config.get('db_port') if 'db_port' in self.__db_config else 5432
        except KeyError:
            print('one of the config values is missing. Please check the config file.')
            sys.exit(1)
        self.__engine = create_engine('postgresql+psycopg2://%s:%s@%s:%d/%s' % (self.__db_user,
                                                                                self.__db_passwd,
                                                                                self.__db_host,
                                                                                int(self.__db_port),
                                                                                self.__db_name))
        self.__schema = schema
        self.__metadata = MetaData(self.__engine, schema=self.__schema)
        self.__Base = declarative_base(metadata=self.__metadata)
        self.__Session = sessionmaker(bind=self.__engine)
        self.__session = self.__Session()

    def get_schema_name(self):
        return self.__schema

    def get_engine(self):
        return self.__engine

    def get_base(self):
        return self.__Base

    def get_metadata(self):
        return self.__metadata

    def get_session(self):
        return self.__session

    @staticmethod
    def __load_config(config_path):
        if isinstance(config_path, dict):
            return config_path
        try:
            with open(config_path, 'r') as db_connection:
                try:
                    return yaml.load(db_connection)
                except yaml.YAMLError as e:
                    sys.exit('Error: {0}'.format(e))
        except IOError as e:
            sys.exit('Error {0}) : {1}'.format(e.errno, e.strerror))

    @staticmethod
    def get_hash_id(*args):
        to_md5 = ''.join(str(args))
        id_hash = hashlib.md5(to_md5).hexdigest()
        return id_hash

    @staticmethod
    def get_date(date_format=''):
        return datetime.datetime.now() if date_format == '' else datetime.datetime.now().strftime(date_format)
