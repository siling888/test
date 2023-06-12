import React from 'react';
import './Login.css';

export default class Login extends React.Component {
  constructor(props) {
    super(props);

    // 初始化状态数据
    this.state = {
      loginType: null, // 登录类型：1.微信登录、2.账号登录、3.绑定微信、4.修改密码
      wxLogin: { qrcode: null, color: null, title: null, content: null },
      accountLogin: { phone: null, password: null },
    };

    // 绑定事件和方法
    this.initialize = this.initialize.bind(this); // 初始化
    this.getWxCode = this.getWxCode.bind(this); // 获取微信登录code
    this.wxLogin = this.wxLogin.bind(this); // 微信登录

    // 创建 AbortController 实例
    this.controller = new AbortController();
  };

  // 生命周期--组件挂载后执行
  componentDidMount() {
    this.initialize();
    if (this.props.visible) {
      this.setState({ loginType: 1 }); // 设置默认登录类型 // 考虑props中增加一个属性方便设置默认登录类型
    }
  }

  // 生命周期--组件更新后执行
  componentDidUpdate(prevProps, prevState) {
    if (this.state.loginType !== prevState.loginType) {
      if (this.state.loginType === 1) {
        this.getWxCode();
      } else {
        this.controller.abort(); // 取消未完成的网络请求
      }
    }
  }

  // 生命周期--组件卸载前执行
  componentWillUnmount() {
    this.controller.abort(); // 取消未完成的网络请求
  }

  // 事件--初始化
  initialize() {
    this.props.onInitialize && this.props.onInitialize();
  }

  // 事件--微信登录
  wxLogin(wxCode) {
    this.props.onWxLogin && this.props.onWxLogin({ wxCode: wxCode });
  }

  // 定义getWxCode方法获取微信授权code
  getWxCode(uuid, last) {
    if (uuid) {
      let url = new URL('https://weixin.openapi.site/check');
      url.searchParams.append('uuid', uuid);
      if (last) {
        url.searchParams.append("last", last);
      }
      // 使用fetch发送GET请求
      fetch(url.toString(), { signal: this.controller.signal })
        .then((response) => response.json())
        .then((data) => {
          if (data.status === 405) {
            this.setState((prevState) => ({
              wxLogin: {
                ...prevState.wxLogin,
                color: '#07c160',
                title: '授权成功',
                content: '系统后台正在进行登录中'
              }
            }));
            this.userLogin_wx(data.result.code);
          } else if (data.status === 404) {
            this.setState((prevState) => ({
              wxLogin: {
                ...prevState.wxLogin,
                color: '#07c160',
                title: '扫描成功',
                content: '请在微信中允许即可登录'
              }
            }));
            this.getWxCode(uuid, data.result.wxErrCode);
          } else if (data.status === 403) {
            this.setState((prevState) => ({
              wxLogin: {
                ...prevState.wxLogin,
                color: '#ffa800',
                title: '取消登录',
                content: '再次扫描登录或关闭窗口'
              }
            }));
            this.getWxCode(uuid, data.result.wxErrCode);
          } else if (data.status === 500) {
            this.setState((prevState) => ({
              wxLogin: {
                ...prevState.wxLogin,
                color: '#fa5151',
                title: '等待超时', // i标签渲染条件为title==='等待超时'，因此title:'等待超时'禁止修改
                content: '点击刷新重新获取二维码'
              }
            }));
          } else {
            setTimeout(() => {
              this.getWxCode(uuid);
            }, 2000);
          }
        })
        .catch((error) => {
          if (error.name !== 'AbortError') {
            setTimeout(() => {
              this.getWxCode(uuid);
            }, 2000);
          }
        });
    } else {
      this.setState({ wxLogin: { title: '正在获取', content: "正在获取微信登录二维码" } });
      let { wx_appid, wx_redirect_uri } = this.props;

      let url = new URL('https://weixin.openapi.site/img');
      url.searchParams.append('appid', wx_appid);
      url.searchParams.append('redirect_uri', wx_redirect_uri);

      // 使用fetch发送GET请求
      fetch(url.toString(), { signal: this.controller.signal })
        .then((response) => response.json())
        .then((data) => {
          if (data.status === 1) {
            this.setState({ wxLogin: { qrcode: data.result.imgData, title: '欢迎登录', content: "打开微信扫一扫功能登录" } });
            this.getWxCode(data.result.wxUUID);
          } else {
            this.setState({ wxLogin: { color: '#fa5151', title: '请求失败', content: data.msg } });
          }
        })
        .catch((error) => {
          if (error.name !== 'AbortError') {
            setTimeout(() => {
              this.getWxCode();
            }, 2000);
          }
        });
    }
  };

  // 渲染主界面
  render() {
    let { visible, width, height, top, bottom, left, right, zIndex, backgroundColor, borderWidth, borderColor, borderStyle, borderRadius } = this.props;

    let style = {
      width: width || '320px',
      height: height || '480px',
      top: top || 'auto',
      bottom: bottom || 'auto',
      left: left || 'auto',
      right: right || 'auto',
      zIndex: zIndex || 'auto',
      backgroundColor: backgroundColor || '#192330',
      borderWidth: borderWidth || '',
      borderColor: borderColor || '',
      borderStyle: borderStyle || '',
      borderRadius: borderRadius || ''
    };

    return visible ? (
      <div className='login' style={style}>
        <h3 className='loginTitle'>微信登录</h3>
        <div className='wxLogin' style={{ display: 'contents', color: this.state.wxLogin.color }}>
          <div>
            {this.state.wxLogin.qrcode && <img src={this.state.wxLogin.qrcode} alt="二维码" />}
            {this.state.wxLogin.title && this.state.wxLogin.title === '等待超时' && <i onClick={() => this.getWxCode()} />}
          </div>
          <h4>{this.state.wxLogin.title}</h4>
          <p>{this.state.wxLogin.content}</p>
        </div>
      </div >
    ) : null
  }
}
